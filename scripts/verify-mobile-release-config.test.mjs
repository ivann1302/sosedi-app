import assert from 'node:assert/strict';
import test from 'node:test';

import { verifyMobileReleaseConfig } from './verify-mobile-release-config.mjs';

const valid = {
  APP_ENVIRONMENT: 'production',
  APP_RELEASE: 'sosedi@1.0.0+42',
  RELEASE_COMMIT_SHA: 'a'.repeat(40),
  API_BASE_URL: 'https://api.sosedi.ru/api/v1',
  MARKETPLACE_OFFER_VERSION: '2026-08-01.1',
  MARKETPLACE_OFFER_URL:
    'https://docs.sosedi.ru/documents/offer/2026-08-01.1/',
  MARKETPLACE_CANCELLATION_POLICY_VERSION: '2026-08-01.2',
  MARKETPLACE_RENTAL_RULES_URL:
    'https://docs.sosedi.ru/documents/rental-rules/2026-08-01.2/',
  MARKETPLACE_PRIVACY_VERSION: '2026-08-01.3',
  MARKETPLACE_PRIVACY_URL:
    'https://docs.sosedi.ru/documents/privacy/2026-08-01.3/',
};

test('accepts a complete production mobile config', () => {
  assert.doesNotThrow(() => verifyMobileReleaseConfig(valid));
});

test('rejects local hosts or a non-production artifact', () => {
  assert.throws(
    () =>
      verifyMobileReleaseConfig({
        ...valid,
        API_BASE_URL: 'http://localhost:3000/api/v1',
      }),
    /clean HTTPS URL/u,
  );
  assert.throws(
    () =>
      verifyMobileReleaseConfig({
        ...valid,
        APP_ENVIRONMENT: 'staging',
    }),
    /must be production/u,
  );
  assert.throws(
    () =>
      verifyMobileReleaseConfig({
        ...valid,
        RELEASE_COMMIT_SHA: 'short',
      }),
    /full Git commit SHA/u,
  );
  assert.throws(
    () =>
      verifyMobileReleaseConfig({
        ...valid,
        APP_RELEASE: 'release-42',
      }),
    /sosedi@MAJOR\.MINOR\.PATCH\+BUILD/u,
  );
  assert.throws(
    () =>
      verifyMobileReleaseConfig({
        ...valid,
        API_BASE_URL: 'https://localhost:3000/api/v1',
      }),
    /clean HTTPS URL/u,
  );
  assert.throws(
    () =>
      verifyMobileReleaseConfig({
        ...valid,
        MARKETPLACE_OFFER_URL:
          'https://127.0.0.1/documents/offer/2026-08-01.1/',
      }),
    /clean HTTPS URL/u,
  );
});

test('rejects draft and mismatched marketplace documents', () => {
  assert.throws(
    () =>
      verifyMobileReleaseConfig({
        ...valid,
        MARKETPLACE_OFFER_VERSION: 'draft-2026-08-01',
        MARKETPLACE_OFFER_URL:
          'https://docs.sosedi.ru/documents/offer/draft-2026-08-01/',
      }),
    /approved version/u,
  );
  assert.throws(
    () =>
      verifyMobileReleaseConfig({
        ...valid,
        MARKETPLACE_RENTAL_RULES_URL:
          'https://docs.sosedi.ru/documents/rental-rules/old-version/',
      }),
    /exact approved version/u,
  );
  assert.throws(
    () =>
      verifyMobileReleaseConfig({
        ...valid,
        MARKETPLACE_PRIVACY_VERSION: '',
        MARKETPLACE_PRIVACY_URL: '',
      }),
    /approved version/u,
  );
});
