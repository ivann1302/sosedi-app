import { type INestApplication, ValidationPipe } from '@nestjs/common';
import {
  json,
  type Application,
  type NextFunction,
  type Request,
  type Response,
  urlencoded,
} from 'express';
import helmet from 'helmet';
import type { Server } from 'node:http';
import { isIP } from 'node:net';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';

export type AppSetupOptions = {
  trustedProxyIps?: string;
  nodeEnv?: string;
  corsAllowedOrigins?: string;
  bodyLimit?: string;
  minSupportedMobileVersion?: string;
  androidUpdateUrl?: string;
  iosUpdateUrl?: string;
};

export type HttpServerTimeoutOptions = {
  requestTimeoutMs?: number;
  headersTimeoutMs?: number;
  keepAliveTimeoutMs?: number;
};

export function configureApp(
  app: INestApplication,
  options: AppSetupOptions = {},
): void {
  const nodeEnv = options.nodeEnv ?? process.env.NODE_ENV ?? 'development';
  configureTrustedProxy(
    app,
    options.trustedProxyIps ?? process.env.TRUSTED_PROXY_IPS ?? '',
  );
  configureCors(
    app,
    options.corsAllowedOrigins ?? process.env.CORS_ALLOWED_ORIGINS ?? '',
    nodeEnv,
  );
  configureSecurityHeaders(app);
  configureHttps(app, nodeEnv);
  configureCompatibilityGate(app, {
    minSupportedMobileVersion:
      options.minSupportedMobileVersion ??
      process.env.MIN_SUPPORTED_MOBILE_VERSION ??
      '1.0.0',
    androidUpdateUrl:
      options.androidUpdateUrl ?? process.env.ANDROID_UPDATE_URL ?? '',
    iosUpdateUrl: options.iosUpdateUrl ?? process.env.IOS_UPDATE_URL ?? '',
  });
  configureBodyParser(
    app,
    options.bodyLimit ?? process.env.HTTP_BODY_LIMIT ?? '256kb',
  );
  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());
}

export function configureHttpServer(
  server: Server,
  options: HttpServerTimeoutOptions = {},
): void {
  const requestTimeoutMs =
    options.requestTimeoutMs ??
    parseTimeout(
      'HTTP_REQUEST_TIMEOUT_MS',
      process.env.HTTP_REQUEST_TIMEOUT_MS,
      30_000,
    );
  const headersTimeoutMs =
    options.headersTimeoutMs ??
    parseTimeout(
      'HTTP_HEADERS_TIMEOUT_MS',
      process.env.HTTP_HEADERS_TIMEOUT_MS,
      15_000,
    );
  const keepAliveTimeoutMs =
    options.keepAliveTimeoutMs ??
    parseTimeout(
      'HTTP_KEEP_ALIVE_TIMEOUT_MS',
      process.env.HTTP_KEEP_ALIVE_TIMEOUT_MS,
      5_000,
    );

  if (headersTimeoutMs > requestTimeoutMs) {
    throw new Error(
      'HTTP_HEADERS_TIMEOUT_MS не должен превышать HTTP_REQUEST_TIMEOUT_MS',
    );
  }

  server.requestTimeout = requestTimeoutMs;
  server.headersTimeout = headersTimeoutMs;
  server.keepAliveTimeout = keepAliveTimeoutMs;
  server.setTimeout(requestTimeoutMs);
}

function configureTrustedProxy(
  app: INestApplication,
  rawTrustedProxyIps: string,
): void {
  const expressApp = app.getHttpAdapter().getInstance() as Application;
  const trustedProxyIps = parseTrustedProxyIps(rawTrustedProxyIps);
  expressApp.set(
    'trust proxy',
    trustedProxyIps.length === 0 ? false : trustedProxyIps,
  );
}

function configureCors(
  app: INestApplication,
  rawAllowedOrigins: string,
  nodeEnv: string,
): void {
  const allowedOrigins = parseAllowedOrigins(rawAllowedOrigins);
  if (nodeEnv === 'production' && allowedOrigins.length === 0) {
    throw new Error(
      'CORS_ALLOWED_ORIGINS обязателен и не может быть пустым в production',
    );
  }

  app.enableCors({
    origin: allowedOrigins,
    credentials: true,
    methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Authorization',
      'Content-Type',
      'Idempotency-Key',
      'X-Installation-Id',
      'X-CSRF-Token',
      'X-Api-Version',
      'X-Request-Id',
      'X-Mobile-Platform',
      'X-Mobile-Version',
    ],
    exposedHeaders: [
      'X-Api-Version',
      'X-Min-Mobile-Version',
      'X-Mobile-Update-Url',
    ],
  });
}

function configureSecurityHeaders(app: INestApplication): void {
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          frameAncestors: ["'none'"],
        },
      },
      frameguard: { action: 'deny' },
      referrerPolicy: { policy: 'no-referrer' },
    }),
  );
}

function configureHttps(app: INestApplication, nodeEnv: string): void {
  if (nodeEnv !== 'production') {
    return;
  }

  app.use((req: Request, res: Response, next: NextFunction) => {
    if (req.secure) {
      next();
      return;
    }

    res.status(426).json({
      success: false,
      data: null,
      error: {
        code: 'HTTPS_REQUIRED',
        message: 'Для production API требуется HTTPS',
      },
    });
  });
}

type CompatibilityOptions = {
  minSupportedMobileVersion: string;
  androidUpdateUrl: string;
  iosUpdateUrl: string;
};

function configureCompatibilityGate(
  app: INestApplication,
  options: CompatibilityOptions,
): void {
  const apiVersion = '1';
  const minimumVersion = parseVersion(
    'MIN_SUPPORTED_MOBILE_VERSION',
    options.minSupportedMobileVersion,
  );
  const updateUrls = {
    ...options,
    androidUpdateUrl: validateUpdateUrl(
      'ANDROID_UPDATE_URL',
      options.androidUpdateUrl,
    ),
    iosUpdateUrl: validateUpdateUrl('IOS_UPDATE_URL', options.iosUpdateUrl),
  };

  app.use((req: Request, res: Response, next: NextFunction) => {
    if (!req.path.startsWith('/api/v1/')) {
      next();
      return;
    }

    res.setHeader('X-Api-Version', apiVersion);
    res.setHeader('X-Min-Mobile-Version', minimumVersion.raw);

    const requestedApiVersion = req.get('X-Api-Version');
    if (requestedApiVersion && requestedApiVersion !== apiVersion) {
      rejectIncompatibleClient(
        res,
        'API_VERSION_UNSUPPORTED',
        'Эта версия API больше не поддерживается',
      );
      return;
    }

    const rawMobileVersion = req.get('X-Mobile-Version');
    if (!rawMobileVersion) {
      next();
      return;
    }

    const mobileVersion = tryParseVersion(rawMobileVersion);
    if (mobileVersion && compareVersions(mobileVersion, minimumVersion) >= 0) {
      next();
      return;
    }

    const updateUrl = selectUpdateUrl(req.get('X-Mobile-Platform'), updateUrls);
    if (updateUrl) {
      res.setHeader('X-Mobile-Update-Url', updateUrl);
    }
    rejectIncompatibleClient(
      res,
      'MOBILE_UPDATE_REQUIRED',
      `Требуется версия приложения ${minimumVersion.raw} или новее`,
    );
  });
}

type ParsedVersion = {
  raw: string;
  parts: readonly [number, number, number];
};

function parseVersion(name: string, value: string): ParsedVersion {
  const version = tryParseVersion(value);
  if (!version) {
    throw new Error(`${name} должен быть версией вида 1.2.3`);
  }
  return version;
}

function tryParseVersion(value: string): ParsedVersion | null {
  const match = /^(\d+)\.(\d+)\.(\d+)(?:[-+][0-9A-Za-z.-]+)?$/.exec(
    value.trim(),
  );
  if (!match) {
    return null;
  }

  return {
    raw: value.trim(),
    parts: [Number(match[1]), Number(match[2]), Number(match[3])],
  };
}

function compareVersions(left: ParsedVersion, right: ParsedVersion): number {
  for (let index = 0; index < left.parts.length; index += 1) {
    const difference = left.parts[index] - right.parts[index];
    if (difference !== 0) {
      return difference;
    }
  }
  return 0;
}

function validateUpdateUrl(name: string, value: string): string {
  if (value === '') {
    return value;
  }

  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new Error(`${name} должен быть абсолютным HTTPS URL`);
  }
  if (url.protocol !== 'https:' || url.username || url.password) {
    throw new Error(`${name} должен быть абсолютным HTTPS URL без credentials`);
  }
  return url.toString();
}

function selectUpdateUrl(
  platform: string | undefined,
  options: CompatibilityOptions,
): string {
  if (platform === 'ios') {
    return options.iosUpdateUrl;
  }
  if (platform === 'android') {
    return options.androidUpdateUrl;
  }
  return '';
}

function rejectIncompatibleClient(
  response: Response,
  code: string,
  message: string,
): void {
  response.status(426).json({
    success: false,
    data: null,
    error: { code, message },
  });
}

function configureBodyParser(app: INestApplication, bodyLimit: string): void {
  validateBodyLimit(bodyLimit);
  app.use(json({ limit: bodyLimit }));
  app.use(urlencoded({ extended: true, limit: bodyLimit }));
}

function parseTrustedProxyIps(rawValue: string): string[] {
  if (rawValue.trim() === '') {
    return [];
  }

  const entries = rawValue.split(',').map((entry) => entry.trim());
  if (entries.some((entry) => entry === '')) {
    throw new Error(
      'TRUSTED_PROXY_IPS должен содержать непустой список IP/CIDR',
    );
  }

  for (const entry of entries) {
    validateIpOrCidr(entry);
  }
  return entries;
}

function validateIpOrCidr(entry: string): void {
  const [address, prefix, extra] = entry.split('/');
  const version = isIP(address);
  if (version === 0 || extra !== undefined) {
    throw new Error(`Недопустимый TRUSTED_PROXY_IPS: ${entry}`);
  }
  if (prefix === undefined) {
    return;
  }

  const prefixLength = Number(prefix);
  const maximum = version === 4 ? 32 : 128;
  if (
    !Number.isInteger(prefixLength) ||
    prefixLength < 1 ||
    prefixLength > maximum
  ) {
    throw new Error(`Недопустимый TRUSTED_PROXY_IPS: ${entry}`);
  }
}

function parseAllowedOrigins(rawValue: string): string[] {
  if (rawValue.trim() === '') {
    return [];
  }

  const origins = rawValue.split(',').map((entry) => entry.trim());
  if (origins.some((origin) => origin === '')) {
    throw new Error(
      'CORS_ALLOWED_ORIGINS должен содержать непустой список origin',
    );
  }

  for (const origin of origins) {
    let url: URL;
    try {
      url = new URL(origin);
    } catch {
      throw new Error(`Недопустимый CORS_ALLOWED_ORIGINS: ${origin}`);
    }
    if (
      url.origin !== origin ||
      !['http:', 'https:'].includes(url.protocol) ||
      url.username !== '' ||
      url.password !== ''
    ) {
      throw new Error(`Недопустимый CORS_ALLOWED_ORIGINS: ${origin}`);
    }
  }

  return [...new Set(origins)];
}

function validateBodyLimit(value: string): void {
  if (!/^[1-9]\d*(b|kb|mb)$/i.test(value)) {
    throw new Error(
      'HTTP_BODY_LIMIT должен быть положительным размером в b, kb или mb',
    );
  }
}

function parseTimeout(
  name: string,
  rawValue: string | undefined,
  fallback: number,
): number {
  if (rawValue === undefined || rawValue === '') {
    return fallback;
  }

  const value = Number(rawValue);
  if (!Number.isInteger(value) || value <= 0) {
    throw new Error(`${name} должен быть положительным целым числом`);
  }
  return value;
}
