import { type INestApplication } from '@nestjs/common';
import {
  DocumentBuilder,
  SwaggerModule,
  type OpenAPIObject,
} from '@nestjs/swagger';
import { Test } from '@nestjs/testing';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { AppController } from '../../app.controller';
import { AppService } from '../../app.service';
import {
  BOOKING_STATUSES,
  DISPUTE_STATUSES,
  PAYMENT_STATUSES,
  PAYOUT_STATUSES,
  WORKFLOW_CONTRACTS,
} from './workflow-contract';

const expectedStatuses = {
  BookingStatus: BOOKING_STATUSES,
  PaymentStatus: PAYMENT_STATUSES,
  PayoutStatus: PAYOUT_STATUSES,
  DisputeStatus: DISPUTE_STATUSES,
} as const;

function enumValues(source: string, enumName: string): string[] {
  const block = source.match(
    new RegExp(`enum ${enumName} \\{([\\s\\S]*?)\\n\\}`),
  )?.[1];
  if (!block) {
    throw new Error(`Missing enum ${enumName}`);
  }

  return Array.from(block.matchAll(/^\s*([A-Z][A-Z_]*)\s*$/gm), (match) => {
    return match[1];
  });
}

function dartWireValues(source: string, enumName: string): string[] {
  const block = source.match(
    new RegExp(`enum ${enumName} \\{([\\s\\S]*?)\\n\\}`),
  )?.[1];
  if (!block) {
    throw new Error(`Missing Dart enum ${enumName}`);
  }

  return Array.from(block.matchAll(/\('([A-Z][A-Z_]*)'\)/g), (match) => {
    return match[1];
  });
}

function openApiEnum(document: OpenAPIObject, schemaName: string): string[] {
  const schema = document.components?.schemas?.[schemaName];
  if (!schema || !('properties' in schema)) {
    throw new Error(`Missing OpenAPI schema ${schemaName}`);
  }

  const status = schema.properties?.status;
  if (!status) {
    throw new Error(`Missing status enum in OpenAPI schema ${schemaName}`);
  }

  if ('enum' in status && Array.isArray(status.enum)) {
    return status.enum.map(String);
  }

  const directRef = '$ref' in status ? status.$ref : undefined;
  const allOfRef =
    'allOf' in status && Array.isArray(status.allOf)
      ? status.allOf.find(
          (item): item is { $ref: string } =>
            typeof item === 'object' &&
            item !== null &&
            '$ref' in item &&
            typeof item.$ref === 'string',
        )?.$ref
      : undefined;
  const reference = directRef ?? allOfRef;

  if (reference) {
    const referencedName = reference.split('/').at(-1);
    const referencedSchema = referencedName
      ? document.components?.schemas?.[referencedName]
      : undefined;
    if (
      referencedSchema &&
      'enum' in referencedSchema &&
      Array.isArray(referencedSchema.enum)
    ) {
      return referencedSchema.enum.map(String);
    }
  }

  throw new Error(
    `Missing status enum in OpenAPI schema ${schemaName}: ${JSON.stringify(status)}`,
  );
}

describe('Workflow contract synchronization', () => {
  let app: INestApplication | undefined;
  let document: OpenAPIObject;

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        {
          provide: AppService,
          useValue: {
            getHealth: jest.fn(),
            getLiveness: jest.fn(),
            getReadiness: jest.fn(),
          },
        },
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    document = SwaggerModule.createDocument(app, new DocumentBuilder().build());
  });

  it('keeps canonical transitions internally valid', () => {
    for (const contract of Object.values(WORKFLOW_CONTRACTS)) {
      const statuses = new Set<string>(contract.statuses);

      for (const transition of contract.transitions) {
        expect(statuses.has(transition.from)).toBe(true);
        expect(statuses.has(transition.to)).toBe(true);
        expect(transition.from).not.toBe(transition.to);
        expect(transition.actors.length).toBeGreaterThan(0);
        expect(transition.preconditions.length).toBeGreaterThan(0);
      }
    }

    expect(BOOKING_STATUSES).not.toContain('PAID');
    expect(PAYMENT_STATUSES).not.toContain('CANCELED');
  });

  it('uses borrower and lender capabilities for booking actors', () => {
    expect(
      WORKFLOW_CONTRACTS.booking.transitions.map(
        ({ command, from, actors }) => ({
          command,
          from,
          actors,
        }),
      ),
    ).toEqual([
      { command: 'confirm', from: 'PENDING', actors: ['LENDER'] },
      {
        command: 'cancel',
        from: 'PENDING',
        actors: ['BORROWER', 'LENDER'],
      },
      { command: 'expire', from: 'PENDING', actors: ['SYSTEM'] },
      {
        command: 'cancel',
        from: 'CONFIRMED',
        actors: ['BORROWER', 'LENDER'],
      },
      {
        command: 'activate',
        from: 'CONFIRMED',
        actors: ['BORROWER', 'LENDER'],
      },
      {
        command: 'return',
        from: 'ACTIVE',
        actors: ['BORROWER', 'LENDER'],
      },
      { command: 'complete', from: 'RETURNED', actors: ['SYSTEM'] },
    ]);
  });

  it('matches Prisma, OpenAPI, and mobile wire mappings', () => {
    const prisma = readFileSync(
      resolve(process.cwd(), 'prisma/schema.prisma'),
      'utf8',
    );
    const mobile = readFileSync(
      resolve(
        process.cwd(),
        '../mobile/lib/shared/models/workflow_status.dart',
      ),
      'utf8',
    );

    for (const [enumName, statuses] of Object.entries(expectedStatuses)) {
      expect(enumValues(prisma, enumName)).toEqual(statuses);
      expect(dartWireValues(mobile, enumName)).toEqual(statuses);
      expect(openApiEnum(document, `${enumName}Dto`)).toEqual(statuses);
    }
  });

  afterAll(async () => {
    await app?.close();
  });
});
