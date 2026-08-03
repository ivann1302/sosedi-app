import type { Request } from 'express';
import { createHash, randomUUID } from 'node:crypto';
import { getClientIp } from '../common/http/client-ip';

export type AdminAuditContext = {
  requestId: string;
  ipAddress: string;
  deviceId: string | null;
};

export function getAdminAuditContext(request: Request): AdminAuditContext {
  const requestIdHeader = request.headers['x-request-id'];
  const requestId =
    typeof requestIdHeader === 'string' &&
    /^[A-Za-z0-9._-]{8,100}$/.test(requestIdHeader)
      ? requestIdHeader
      : randomUUID();
  const userAgent = request.headers['user-agent'];

  return {
    requestId,
    ipAddress: getClientIp(request),
    deviceId: userAgent
      ? createHash('sha256').update(userAgent).digest('hex').slice(0, 32)
      : null,
  };
}
