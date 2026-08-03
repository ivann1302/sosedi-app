import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

const versionPattern = /^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/u;
const dartDefineKeys = Object.freeze([
  'APP_ENVIRONMENT',
  'APP_RELEASE',
  'API_BASE_URL',
  'MARKETPLACE_OFFER_VERSION',
  'MARKETPLACE_OFFER_URL',
  'MARKETPLACE_CANCELLATION_POLICY_VERSION',
  'MARKETPLACE_RENTAL_RULES_URL',
  'MARKETPLACE_PRIVACY_VERSION',
  'MARKETPLACE_PRIVACY_URL',
]);

export function verifyMobileReleaseConfig(config) {
  if (config.APP_ENVIRONMENT !== 'production') {
    throw new Error('APP_ENVIRONMENT must be production');
  }
  requireRelease(config.APP_RELEASE);
  requireCommitSha(config.RELEASE_COMMIT_SHA);
  requireApiUrl(config.API_BASE_URL);
  requireDocument(
    'MARKETPLACE_OFFER_URL',
    config.MARKETPLACE_OFFER_URL,
    config.MARKETPLACE_OFFER_VERSION,
  );
  requireDocument(
    'MARKETPLACE_RENTAL_RULES_URL',
    config.MARKETPLACE_RENTAL_RULES_URL,
    config.MARKETPLACE_CANCELLATION_POLICY_VERSION,
  );
  requireDocument(
    'MARKETPLACE_PRIVACY_URL',
    config.MARKETPLACE_PRIVACY_URL,
    config.MARKETPLACE_PRIVACY_VERSION,
  );
}

export function mobileReleaseDartDefineArgs(config) {
  verifyMobileReleaseConfig(config);
  return dartDefineKeys.map(
    (key) => `--dart-define=${key}=${config[key]}`,
  );
}

function requireCommitSha(value) {
  if (
    typeof value !== 'string' ||
    !/^[a-f0-9]{40}$|^[a-f0-9]{64}$/u.test(value)
  ) {
    throw new Error('RELEASE_COMMIT_SHA must be a full Git commit SHA');
  }
}

function requireRelease(value) {
  parseMobileAppRelease(value);
}

export function parseMobileAppRelease(value) {
  const match =
    typeof value === 'string'
      ? /^sosedi@(\d+\.\d+\.\d+)\+([1-9]\d{0,9})$/u.exec(value)
      : null;
  if (!match) {
    throw new Error(
      'APP_RELEASE must use sosedi@MAJOR.MINOR.PATCH+BUILD',
    );
  }
  return { buildName: match[1], buildNumber: match[2] };
}

function requireApiUrl(value) {
  const url = secureUrl('API_BASE_URL', value);
  if (url.pathname.replace(/\/+$/u, '') !== '/api/v1') {
    throw new Error('API_BASE_URL must end with /api/v1');
  }
}

function requireDocument(name, rawUrl, version) {
  if (
    typeof version !== 'string' ||
    !versionPattern.test(version) ||
    /draft/iu.test(version)
  ) {
    throw new Error(`${name} requires an approved version`);
  }
  const url = secureUrl(name, rawUrl);
  const segments = url.pathname
    .split('/')
    .filter(Boolean)
    .map((segment) => decodeURIComponent(segment));
  if (!segments.includes(version)) {
    throw new Error(`${name} must contain its exact approved version`);
  }
}

function secureUrl(name, value) {
  let url;
  try {
    url = new URL(value);
  } catch {
    throw new Error(`${name} must be an absolute HTTPS URL`);
  }
  if (
    url.protocol !== 'https:' ||
    !isPublicHostname(url.hostname) ||
    url.username ||
    url.password ||
    url.search ||
    url.hash
  ) {
    throw new Error(`${name} must be an absolute clean HTTPS URL`);
  }
  return url;
}

function isPublicHostname(value) {
  const hostname = value.toLowerCase();
  return (
    hostname.includes('.') &&
    !hostname.endsWith('.') &&
    !hostname.includes(':') &&
    !/^\d{1,3}(?:\.\d{1,3}){3}$/u.test(hostname) &&
    !['.local', '.localhost', '.test', '.invalid', '.example'].some((suffix) =>
      hostname.endsWith(suffix),
    )
  );
}

function main() {
  verifyMobileReleaseConfig(process.env);
  process.stdout.write('Mobile production release config is valid\n');
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href
) {
  try {
    main();
  } catch (error) {
    process.stderr.write(
      `Mobile release config verification failed: ${
        error instanceof Error ? error.message : 'unknown error'
      }\n`,
    );
    process.exitCode = 1;
  }
}
