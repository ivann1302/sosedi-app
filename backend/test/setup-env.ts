// E2E tests never inherit production connection URLs by accident.
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL =
  process.env.TEST_DATABASE_URL ??
  'postgresql://sosedi_test:sosedi_test@localhost:5435/sosedi_test?schema=public';
process.env.REDIS_URL =
  process.env.TEST_REDIS_URL ?? 'redis://localhost:6380/15';

process.env.JWT_ACCESS_SECRET = 'e2e-access-secret';
process.env.JWT_REFRESH_SECRET = 'e2e-refresh-secret';
process.env.JWT_ACCESS_EXPIRES_IN = '15m';
process.env.JWT_REFRESH_EXPIRES_IN = '30d';
process.env.SMS_PROVIDER = 'console';
process.env.SMS_API_KEY = 'change_me';
