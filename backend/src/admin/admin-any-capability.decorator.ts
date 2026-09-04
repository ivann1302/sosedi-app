import { applyDecorators, SetMetadata } from '@nestjs/common';
import { ApiForbiddenResponse } from '@nestjs/swagger';
import { AdminCapability } from '@prisma/client';

export const ADMIN_ANY_CAPABILITY_KEY = 'adminAnyCapability';

export const AdminAnyCapability = (...capabilities: AdminCapability[]) =>
  applyDecorators(
    SetMetadata(ADMIN_ANY_CAPABILITY_KEY, capabilities),
    ApiForbiddenResponse({
      description: `Требуется одно из административных полномочий: ${capabilities.join(', ')}`,
    }),
  );
