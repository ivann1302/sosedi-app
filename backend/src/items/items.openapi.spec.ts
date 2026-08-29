import { type INestApplication } from '@nestjs/common';
import {
  DocumentBuilder,
  SwaggerModule,
  type OpenAPIObject,
} from '@nestjs/swagger';
import { Test } from '@nestjs/testing';
import { configureApp } from '../app.setup';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ItemsController } from './items.controller';
import { ItemsService } from './items.service';

function asRecord(value: unknown): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error('Expected an object');
  }

  return value as Record<string, unknown>;
}

describe('Items OpenAPI contract', () => {
  let app: INestApplication | undefined;
  let document: OpenAPIObject;

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      controllers: [ItemsController],
      providers: [{ provide: ItemsService, useValue: {} }],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(RolesGuard)
      .useValue({ canActivate: () => true })
      .compile();

    app = moduleFixture.createNestApplication();
    configureApp(app);
    document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().addBearerAuth().build(),
    );
  });

  it('documents geo query fields and UUID path parameters', () => {
    const listOperation = document.paths['/api/v1/items']?.get;
    const cardOperation = document.paths['/api/v1/items/{id}']?.get;

    expect(listOperation?.parameters).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ in: 'query', name: 'latitude' }),
        expect.objectContaining({ in: 'query', name: 'longitude' }),
        expect.objectContaining({ in: 'query', name: 'radiusKm' }),
        expect.objectContaining({ in: 'query', name: 'sort' }),
        expect.objectContaining({ in: 'query', name: 'area' }),
      ]),
    );
    expect(cardOperation?.parameters).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          in: 'path',
          name: 'id',
        }),
      ]),
    );
    const idParameter = cardOperation?.parameters?.find((parameter) => {
      return 'name' in parameter && parameter.name === 'id';
    });
    if (!idParameter) {
      throw new Error('Expected the item id path parameter');
    }
    expect(asRecord(asRecord(idParameter).schema)).toMatchObject({
      format: 'uuid',
    });

    for (const name of ['limit', 'offset']) {
      const parameter = listOperation?.parameters?.find((candidate) => {
        return 'name' in candidate && candidate.name === name;
      });
      if (!parameter) {
        throw new Error(`Expected the ${name} query parameter`);
      }
      expect(asRecord(asRecord(parameter).schema)).toMatchObject({
        type: 'integer',
      });
    }
  });

  it('documents the public area choices endpoint', () => {
    const areasOperation = document.paths['/api/v1/items/areas']?.get;

    expect(areasOperation?.responses['200']).toBeDefined();
  });

  it('keeps exact location and original photos out of the public schema', () => {
    const schemas = document.components?.schemas;
    if (!schemas) {
      throw new Error('Expected OpenAPI component schemas');
    }

    const publicProperties = asRecord(
      asRecord(schemas.PublicItemResponseDto).properties,
    );
    const privateProperties = asRecord(
      asRecord(schemas.PrivateItemResponseDto).properties,
    );
    const publicPhotoProperties = asRecord(
      asRecord(schemas.PublicItemPhotoResponseDto).properties,
    );

    expect(publicProperties).toHaveProperty('area');
    expect(publicProperties).toHaveProperty('approximateLocation');
    expect(publicProperties).toHaveProperty('distanceBucket');
    expect(publicProperties).toHaveProperty('condition');
    expect(publicProperties).toHaveProperty('completeness');
    expect(publicProperties).toHaveProperty('handoverTerms');
    expect(publicProperties).not.toHaveProperty('address');
    expect(publicProperties).not.toHaveProperty('latitude');
    expect(publicProperties).not.toHaveProperty('longitude');
    expect(publicPhotoProperties).not.toHaveProperty('originalUrl');

    expect(privateProperties).toHaveProperty('address');
    expect(privateProperties).toHaveProperty('latitude');
    expect(privateProperties).toHaveProperty('longitude');
  });

  it('documents that new items do not support a non-zero deposit', () => {
    const schemas = document.components?.schemas;
    if (!schemas) {
      throw new Error('Expected OpenAPI component schemas');
    }

    const createItemProperties = asRecord(
      asRecord(schemas.CreateItemDto).properties,
    );

    expect(asRecord(createItemProperties.depositAmount)).toMatchObject({
      enum: [0],
      maximum: 0,
      minimum: 0,
    });
  });

  afterAll(async () => {
    await app?.close();
  });
});
