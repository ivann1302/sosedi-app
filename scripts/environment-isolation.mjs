import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

const ENVIRONMENTS = ['local', 'staging', 'production'];
const REQUIRED_KEYS = [
  'DEPLOYMENT_ENVIRONMENT',
  'PROVIDER_MODE',
  'NONPRODUCTION_DATA_POLICY',
  'DATABASE_URL',
  'REDIS_URL',
  'JWT_ACCESS_SECRET',
  'JWT_REFRESH_SECRET',
  'ADMIN_MFA_ENCRYPTION_KEY',
  'METRICS_TOKEN',
  'S3_ENDPOINT',
  'S3_BUCKET_PUBLIC',
  'S3_BUCKET_PRIVATE',
  'S3_ACCESS_KEY',
  'SMS_PROVIDER',
  'SMS_PROVIDER_MODE',
  'PAYMENT_PROVIDER_MODE',
  'PUSH_PROVIDER_MODE',
];
const DISTINCT_KEYS = [
  'DATABASE_URL',
  'REDIS_URL',
  'JWT_ACCESS_SECRET',
  'JWT_REFRESH_SECRET',
  'ADMIN_MFA_ENCRYPTION_KEY',
  'METRICS_TOKEN',
  'S3_BUCKET_PUBLIC',
  'S3_BUCKET_PRIVATE',
  'S3_ACCESS_KEY',
];

function fail(message) {
  throw new Error(message);
}

export function parseEnv(contents) {
  const values = new Map();
  for (const [index, rawLine] of contents.split(/\r?\n/).entries()) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    const separator = line.indexOf('=');
    if (separator < 1) fail(`Invalid env line ${index + 1}`);
    const key = line.slice(0, separator).trim();
    let value = line.slice(separator + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (values.has(key)) fail(`Duplicate env key: ${key}`);
    values.set(key, value);
  }
  return values;
}

export function verifyEnvironmentIsolation(configs) {
  for (const name of ENVIRONMENTS) {
    const config = configs[name];
    if (!config) fail(`Missing ${name} environment`);
    for (const key of REQUIRED_KEYS) {
      const value = config.get(key) ?? '';
      if (!value || /change_me|replace_me|example/i.test(value)) {
        fail(`${name}: ${key} is missing or contains a placeholder`);
      }
    }
    if (config.get('DEPLOYMENT_ENVIRONMENT') !== name) {
      fail(`${name}: DEPLOYMENT_ENVIRONMENT mismatch`);
    }
    new URL(config.get('DATABASE_URL'));
    new URL(config.get('REDIS_URL'));
    new URL(config.get('S3_ENDPOINT'));
  }

  expectMode(configs.local, 'local', 'local', 'console');
  expectMode(configs.staging, 'test', 'test', 'smsru');
  expectMode(configs.production, 'live', 'live', 'smsru');
  expectOneOf(configs.local, 'PAYMENT_PROVIDER_MODE', ['disabled', 'fake']);
  expectOneOf(configs.local, 'PUSH_PROVIDER_MODE', ['disabled', 'fake']);
  for (const key of ['PAYMENT_PROVIDER_MODE', 'PUSH_PROVIDER_MODE']) {
    expectOneOf(configs.staging, key, ['disabled', 'test']);
    expectOneOf(configs.production, key, ['disabled', 'live']);
  }

  expectOneOf(configs.local, 'NONPRODUCTION_DATA_POLICY', [
    'synthetic-only',
    'anonymized',
  ]);
  expectOneOf(configs.staging, 'NONPRODUCTION_DATA_POLICY', [
    'synthetic-only',
    'anonymized',
  ]);
  if (configs.production.get('NONPRODUCTION_DATA_POLICY') !== 'production') {
    fail('production: NONPRODUCTION_DATA_POLICY must be production');
  }

  for (const key of DISTINCT_KEYS) {
    const values = ENVIRONMENTS.map((name) => configs[name].get(key));
    if (new Set(values).size !== values.length) {
      fail(`${key} must differ across all environments`);
    }
  }

  for (const name of ENVIRONMENTS) {
    const config = configs[name];
    if (config.get('S3_BUCKET_PUBLIC') === config.get('S3_BUCKET_PRIVATE')) {
      fail(`${name}: public and private S3 buckets must differ`);
    }
  }
  const productionValues = [
    configs.production.get('DATABASE_URL'),
    configs.production.get('REDIS_URL'),
    configs.production.get('S3_ENDPOINT'),
  ].join(' ');
  if (/localhost|127\.0\.0\.1|\.test(?:[/:]|$)/i.test(productionValues)) {
    fail('production endpoints must not use local or test hosts');
  }
}

function expectMode(config, providerMode, smsMode, smsProvider) {
  if (
    config.get('PROVIDER_MODE') !== providerMode ||
    config.get('SMS_PROVIDER_MODE') !== smsMode ||
    config.get('SMS_PROVIDER') !== smsProvider
  ) {
    fail(`Provider mode mismatch for ${providerMode}`);
  }
}

function expectOneOf(config, key, allowed) {
  if (!allowed.includes(config.get(key))) {
    fail(`${key} must be one of: ${allowed.join(', ')}`);
  }
}

async function main() {
  const paths = {
    local: process.env.LOCAL_ENV_FILE,
    staging: process.env.STAGING_ENV_FILE,
    production: process.env.PRODUCTION_ENV_FILE,
  };
  const configs = {};
  for (const name of ENVIRONMENTS) {
    const path = paths[name];
    if (!path) fail(`${name.toUpperCase()}_ENV_FILE is required`);
    configs[name] = parseEnv(await readFile(path, 'utf8'));
  }
  verifyEnvironmentIsolation(configs);
  process.stdout.write('Environment credentials and provider modes are isolated\n');
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 2;
  });
}
