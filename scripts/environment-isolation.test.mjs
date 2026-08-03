import assert from 'node:assert/strict';
import test from 'node:test';
import { parseEnv, verifyEnvironmentIsolation } from './environment-isolation.mjs';

function config(name, providerMode, smsProvider, paymentMode, pushMode) {
  return parseEnv(`
DEPLOYMENT_ENVIRONMENT=${name}
PROVIDER_MODE=${providerMode}
NONPRODUCTION_DATA_POLICY=${name === 'production' ? 'production' : 'synthetic-only'}
DATABASE_URL=postgresql://user:secret@${name}.db.internal:5432/sosedi_${name}
REDIS_URL=redis://:${name}-secret@${name}.redis.internal:6379/0
JWT_ACCESS_SECRET=${name}-jwt-access-secret-long
JWT_REFRESH_SECRET=${name}-jwt-refresh-secret-long
ADMIN_MFA_ENCRYPTION_KEY=${name}-admin-mfa-key-long
METRICS_TOKEN=${name}-metrics-token-with-32-characters
S3_ENDPOINT=https://s3.internal
S3_BUCKET_PUBLIC=sosedi-${name}-public
S3_BUCKET_PRIVATE=sosedi-${name}-private
S3_ACCESS_KEY=${name}-s3-access-identity
SMS_PROVIDER=${smsProvider}
SMS_PROVIDER_MODE=${providerMode}
PAYMENT_PROVIDER_MODE=${paymentMode}
PUSH_PROVIDER_MODE=${pushMode}
`);
}

function validConfigs() {
  return {
    local: config('local', 'local', 'console', 'fake', 'disabled'),
    staging: config('staging', 'test', 'smsru', 'test', 'test'),
    production: config('production', 'live', 'smsru', 'disabled', 'disabled'),
  };
}

test('accepts isolated credentials, data and provider modes', () => {
  assert.doesNotThrow(() => verifyEnvironmentIsolation(validConfigs()));
});

test('rejects a database reused across environments', () => {
  const configs = validConfigs();
  configs.staging.set('DATABASE_URL', configs.production.get('DATABASE_URL'));
  assert.throws(
    () => verifyEnvironmentIsolation(configs),
    /DATABASE_URL must differ/,
  );
});

test('rejects test provider mode in production', () => {
  const configs = validConfigs();
  configs.production.set('PROVIDER_MODE', 'test');
  assert.throws(
    () => verifyEnvironmentIsolation(configs),
    /Provider mode mismatch/,
  );
});
