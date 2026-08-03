import { createHash } from 'node:crypto';
import { Prisma } from '@prisma/client';

export function hashIdempotentPayload(payload: object): string {
  return createHash('sha256').update(JSON.stringify(payload)).digest('hex');
}

export function isUniqueConstraintError(error: unknown): boolean {
  return (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2002'
  );
}
