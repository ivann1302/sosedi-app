import { AdminCapability, UserRole } from '@prisma/client';
import { Request } from 'express';

export type AuthUser = {
  id: string;
  phone: string;
  role: UserRole;
};

export type AdminAuthUser = AuthUser & {
  adminCapabilities: AdminCapability[];
  sessionVersion: number;
};

export type JwtAccessPayload = {
  sub: string;
  phone: string;
  role: UserRole;
  tokenType: 'access';
  sessionVersion: number;
  iat?: number;
  exp?: number;
};

export type JwtRefreshPayload = {
  sub: string;
  phone: string;
  role: UserRole;
  tokenType: 'refresh';
  sessionVersion: number;
  jti: string;
  sid: string;
  iat?: number;
  exp?: number;
};

export type UserStepUpPurpose = 'DATA_EXPORT';

export type JwtUserStepUpPayload = {
  sub: string;
  tokenType: 'user-step-up';
  purpose: UserStepUpPurpose;
  sessionVersion: number;
  jti: string;
  iat?: number;
  exp?: number;
};

export type AuthenticatedRequest = Request & {
  user: AuthUser;
  adminSessionId?: string;
};
