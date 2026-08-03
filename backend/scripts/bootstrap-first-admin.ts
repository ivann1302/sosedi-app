import { PrismaClient } from '@prisma/client';
import {
  bootstrapFirstAdmin,
  parseBootstrapCapabilities,
} from '../src/admin/first-admin-bootstrap';

const CONFIRMATION = 'CREATE_FIRST_ADMIN';

async function main(): Promise<void> {
  if (process.env.ADMIN_BOOTSTRAP_CONFIRM !== CONFIRMATION) {
    throw new Error(
      `ADMIN_BOOTSTRAP_CONFIRM должен быть равен ${CONFIRMATION}`,
    );
  }

  const phone = process.env.ADMIN_BOOTSTRAP_PHONE;
  const rawCapabilities = process.env.ADMIN_BOOTSTRAP_CAPABILITIES;
  if (!phone || !rawCapabilities) {
    throw new Error(
      'Нужны одноразовые ADMIN_BOOTSTRAP_PHONE и ADMIN_BOOTSTRAP_CAPABILITIES',
    );
  }

  const prisma = new PrismaClient();
  try {
    const result = await bootstrapFirstAdmin(prisma, {
      phone,
      capabilities: parseBootstrapCapabilities(rawCapabilities),
    });
    process.stdout.write(
      `Первый администратор создан: id=${result.id}, capabilities=${result.capabilities.join(',')}\n`,
    );
  } finally {
    await prisma.$disconnect();
  }
}

void main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : 'Неизвестная ошибка';
  process.stderr.write(`Bootstrap отклонён: ${message}\n`);
  process.exitCode = 1;
});
