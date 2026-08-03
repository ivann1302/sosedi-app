import { AdminCapability, PrismaClient, UserRole } from '@prisma/client';
import { normalizeRussianPhone } from '../auth/auth.util';

const BOOTSTRAP_LOCK_ID = 736625041;
const BOOTSTRAP_CAPABILITIES = new Set<AdminCapability>([
  AdminCapability.MODERATION,
  AdminCapability.SUPPORT,
]);

export type FirstAdminBootstrapInput = {
  phone: string;
  capabilities: AdminCapability[];
};

export function parseBootstrapCapabilities(value: string): AdminCapability[] {
  const capabilities = [
    ...new Set(value.split(',').map((part) => part.trim())),
  ];

  if (
    capabilities.length === 0 ||
    capabilities.some(
      (capability) =>
        !BOOTSTRAP_CAPABILITIES.has(capability as AdminCapability),
    )
  ) {
    throw new Error(
      'ADMIN_BOOTSTRAP_CAPABILITIES должен содержать MODERATION и/или SUPPORT',
    );
  }

  return capabilities as AdminCapability[];
}

export async function bootstrapFirstAdmin(
  prisma: PrismaClient,
  input: FirstAdminBootstrapInput,
): Promise<{ id: string; capabilities: AdminCapability[] }> {
  const phone = normalizeRussianPhone(input.phone);
  const capabilities = parseBootstrapCapabilities(input.capabilities.join(','));

  return prisma.$transaction(async (tx) => {
    await tx.$executeRaw`SELECT pg_advisory_xact_lock(${BOOTSTRAP_LOCK_ID})`;

    const existingAdmin = await tx.user.findFirst({
      where: { role: UserRole.ADMIN },
      select: { id: true },
    });
    if (existingAdmin) {
      throw new Error('Первый администратор уже создан');
    }

    const existingUser = await tx.user.findUnique({
      where: { phone },
      select: { id: true, isBlocked: true, deletedAt: true },
    });
    if (existingUser?.isBlocked || existingUser?.deletedAt) {
      throw new Error(
        'Нельзя повысить заблокированного или удалённого пользователя',
      );
    }

    const admin = existingUser
      ? await tx.user.update({
          where: { id: existingUser.id },
          data: {
            role: UserRole.ADMIN,
            adminCapabilities: capabilities,
            sessionVersion: { increment: 1 },
          },
          select: { id: true, adminCapabilities: true },
        })
      : await tx.user.create({
          data: {
            phone,
            role: UserRole.ADMIN,
            adminCapabilities: capabilities,
          },
          select: { id: true, adminCapabilities: true },
        });

    await tx.adminAuditLog.create({
      data: {
        adminId: admin.id,
        action: 'FIRST_ADMIN_BOOTSTRAPPED',
        entityType: 'User',
        entityId: admin.id,
        metadata: {
          capabilities: admin.adminCapabilities,
          method: 'OFFLINE_CLI',
        },
      },
    });

    return {
      id: admin.id,
      capabilities: admin.adminCapabilities,
    };
  });
}
