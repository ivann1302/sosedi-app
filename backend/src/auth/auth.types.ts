import { UserRole } from '@prisma/client';
import { Request } from 'express';

export type AuthUser = {
  id: string;
  phone: string;
  role: UserRole;
};

export type JwtAccessPayload = {
  sub: string;
  phone: string;
  role: UserRole;
  tokenType: 'access';
  iat?: number;
  exp?: number;
};

export type JwtRefreshPayload = {
  sub: string;
  phone: string;
  role: UserRole;
  tokenType: 'refresh';
  jti: string;
  iat?: number;
  exp?: number;
};

export type AuthenticatedRequest = Request & {
  user: AuthUser;
};
