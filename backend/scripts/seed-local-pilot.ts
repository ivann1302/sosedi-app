import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import {
  assertLocalPilotSeedAllowed,
  seedLocalPilotData,
} from '../src/operations/local-pilot-seed';

async function main(): Promise<void> {
  assertLocalPilotSeedAllowed(process.env);
  if (process.argv.includes('--check-only')) {
    process.stdout.write('Local pilot seed target accepted\n');
    return;
  }

  const prisma = new PrismaClient();
  try {
    const result = await seedLocalPilotData(prisma);
    process.stdout.write(
      `Local pilot seed ready: users=${result.users}, items=${result.items}, favorites=${result.favorites}\n`,
    );
  } finally {
    await prisma.$disconnect();
  }
}

void main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : 'Unknown error';
  process.stderr.write(`Local pilot seed rejected: ${message}\n`);
  process.exitCode = 1;
});
