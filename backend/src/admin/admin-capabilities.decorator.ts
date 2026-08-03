import { applyDecorators, SetMetadata } from '@nestjs/common';
import { ApiForbiddenResponse } from '@nestjs/swagger';
import { AdminCapability } from '@prisma/client';

export const ADMIN_CAPABILITIES_KEY = 'adminCapabilities';

export const AdminCapabilities = (...capabilities: AdminCapability[]) =>
  applyDecorators(
    SetMetadata(ADMIN_CAPABILITIES_KEY, capabilities),
    ApiForbiddenResponse({
      description: `Требуются административные полномочия: ${capabilities.join(', ')}`,
    }),
  );
