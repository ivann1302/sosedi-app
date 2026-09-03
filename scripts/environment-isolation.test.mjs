import assert from 'node:assert/strict';
import test from 'node:test';
import { parseEnv, verifyEnvironmentIsolation } from './environment-isolation.mjs';

function config(name, providerMode, smsProvider, paymentScenario, pushMode) {
  const fakePolicy =
    name === 'production'
      ? ''
      : `
FAKE_SAFE_DEAL_DEPOSIT_MAX_MINOR=10000000
FAKE_SAFE_DEAL_POLICY_VERSION=fake-deposit-2026-09-02
FAKE_SAFE_DEAL_DISPUTE_WINDOW_SECONDS=300`;
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
PAYMENT_SCENARIO=${paymentScenario}${fakePolicy}
PUSH_PROVIDER_MODE=${pushMode}
`);
}

function validConfigs() {
  return {
    local: config('local', 'local', 'console', 'FAKE_SAFE_DEAL', 'disabled'),
    staging: config('staging', 'test', 'smsru', 'FAKE_SAFE_DEAL', 'test'),
    production: config(
      'production',
      'live',
      'smsru',
      'PAY_ON_HANDOVER',
      'disabled',
    ),
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

test('rejects a non-production payment scenario in production', () => {
  const configs = validConfigs();
  configs.production.set('PAYMENT_SCENARIO', 'FAKE_SAFE_DEAL');
  assert.throws(
    () => verifyEnvironmentIsolation(configs),
    /PAYMENT_SCENARIO must be PAY_ON_HANDOVER/,
  );
});
