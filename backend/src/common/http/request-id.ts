import type { Request } from 'express';
import { randomUUID } from 'node:crypto';

export function getRequestId(request: Request): string {
  const value = request.headers['x-request-id'];
  return typeof value === 'string' && /^[A-Za-z0-9._-]{8,100}$/.test(value)
    ? value
    : randomUUID();
}
