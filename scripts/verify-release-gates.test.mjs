import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { verifyReleaseGate } from './verify-release-gates.mjs';

const now = new Date('2026-07-29T12:00:00.000Z');
const expected = {
  releaseId: 'release-42',
  commitSha: 'a'.repeat(40),
  backendImage: `registry.ru/sosedi/backend@sha256:${'b'.repeat(64)}`,
  paymentScenario: 'PAY_ON_HANDOVER',
  marketplaceOfferVersion: 'offer-v1',
  cancellationPolicyVersion: 'rental-rules-v1',
};

const releaseGateTemplate = JSON.parse(
  readFileSync(
    new URL('../ops/release/release-gate.example.json', import.meta.url),
    'utf8',
  ),
);

function validRecord() {
  return {
    schemaVersion: 1,
    releaseId: expected.releaseId,
    generatedAt: '2026-07-29T11:00:00.000Z',
    commitSha: expected.commitSha,
    backendImage: expected.backendImage,
    ci: { status: 'passed', commitSha: expected.commitSha },
    p0: {
      status: 'passed',
      openFindings: 0,
      checkedAt: '2026-07-29T11:00:00.000Z',
    },
    restore: {
      status: 'passed',
      completedAt: '2026-07-20T10:00:00.000Z',
      postgresRestored: true,
      s3ObjectsRestored: true,
      rpoHours: 5,
      postgresRtoHours: 3,
      s3RtoHours: 7,
      s3Sample: {
        sha256: 'c'.repeat(64),
        sourceKeySha256: 'd'.repeat(64),
        sizeBytes: 1024,
        targetRef: 'rf-restore-bucket/sosedi-restore-sample/release-42',
      },
      evidenceRef: 'restore-record-42',
    },
    marketplaceLegalSafety: {
      status: 'accepted',
      documents: {
        offer: 'offer-v1',
        rentalRules: 'rental-rules-v1',
        privacy: 'privacy-v1',
        prohibitedItems: 'prohibited-items-v1',
      },
      approvalRef: 'legal-approval-42',
    },
    publicLinks: {
      status: 'passed',
      checkedAt: '2026-07-29T11:00:00.000Z',
      urls: {
        offer: 'https://legal.sosedi.ru/documents/offer/offer-v1/',
        rentalRules:
          'https://legal.sosedi.ru/documents/rental-rules/rental-rules-v1/',
        privacy:
          'https://legal.sosedi.ru/documents/privacy/privacy-v1/',
        prohibitedItems:
          'https://legal.sosedi.ru/documents/prohibited/prohibited-items-v1/',
        support: 'https://legal.sosedi.ru/support/',
        accountDeletion: 'https://legal.sosedi.ru/account-deletion/',
      },
    },
    versionedAcceptance: {
      status: 'passed',
      checkedAt: '2026-07-29T11:00:00.000Z',
      evidenceRef: 'acceptance-smoke-42',
    },
    admin: {
      mfaSmoke: 'passed',
      operatorSmoke: 'passed',
      auditSmoke: 'passed',
      checkedAt: '2026-07-29T11:00:00.000Z',
    },
    payment: releaseGateTemplate.payment,
    kyc: { mode: 'disabled', legalGate: 'not-applicable' },
    approvals: {
      productOwner: 'approval-product-42',
      legalOwner: 'approval-legal-42',
    },
  };
}

test('accepts complete evidence for the exact release artifact', () => {
  assert.doesNotThrow(() => verifyReleaseGate(validRecord(), expected, now));
});

test('blocks release with an open P0 finding', () => {
  const record = validRecord();
  record.p0.openFindings = 1;

  assert.throws(
    () => verifyReleaseGate(record, expected, now),
    /Open P0 security\/privacy findings/,
  );
});

test('blocks stale restore evidence', () => {
  const record = validRecord();
  record.restore.completedAt = '2026-01-01T00:00:00.000Z';

  assert.throws(
    () => verifyReleaseGate(record, expected, now),
    /restore.completedAt evidence is stale/,
  );
});

test('blocks boolean-only S3 restore evidence without checksum-bound sample', () => {
  const record = validRecord();
  delete record.restore.s3Sample;

  assert.throws(
    () => verifyReleaseGate(record, expected, now),
    /restore\.s3Sample/,
  );
});

test('blocks FAKE_SAFE_DEAL in a production artifact', () => {
  const record = validRecord();
  record.payment = { scenario: 'FAKE_SAFE_DEAL', legalGate: 'not-applicable' };

  assert.throws(
    () =>
      verifyReleaseGate(
        record,
        { ...expected, paymentScenario: 'FAKE_SAFE_DEAL' },
        now,
      ),
    /Production payment scenario must be PAY_ON_HANDOVER/,
  );
});

test('blocks SAFE_DEAL in a production artifact', () => {
  const record = validRecord();
  record.payment = { scenario: 'SAFE_DEAL', legalGate: 'not-applicable' };

  assert.throws(
    () =>
      verifyReleaseGate(
        record,
        { ...expected, paymentScenario: 'SAFE_DEAL' },
        now,
      ),
    /Production payment scenario must be PAY_ON_HANDOVER/,
  );
});

test('blocks missing, unsafe or wrong-version public legal links', () => {
  const missing = validRecord();
  delete missing.publicLinks.urls.accountDeletion;
  assert.throws(
    () => verifyReleaseGate(missing, expected, now),
    /publicLinks\.urls\.accountDeletion/,
  );

  const unsafe = validRecord();
  unsafe.publicLinks.urls.support = 'http://legal.sosedi.ru/support/';
  assert.throws(
    () => verifyReleaseGate(unsafe, expected, now),
    /publicLinks\.urls\.support/,
  );

  const wrongVersion = validRecord();
  wrongVersion.publicLinks.urls.offer =
    'https://legal.sosedi.ru/documents/offer/old-v1/';
  assert.throws(
    () => verifyReleaseGate(wrongVersion, expected, now),
    /approved document version/,
  );

  const loopback = validRecord();
  loopback.publicLinks.urls.support = 'https://127.0.0.1/support/';
  assert.throws(
    () => verifyReleaseGate(loopback, expected, now),
    /publicLinks\.urls\.support/,
  );
});

test('blocks draft or runtime-mismatched marketplace document versions', () => {
  const draft = validRecord();
  draft.marketplaceLegalSafety.documents.offer = 'draft-offer-v1';
  assert.throws(
    () => verifyReleaseGate(draft, expected, now),
    /marketplaceLegalSafety\.documents\.offer/,
  );

  assert.throws(
    () =>
      verifyReleaseGate(
        validRecord(),
        { ...expected, marketplaceOfferVersion: 'different-offer-v1' },
        now,
      ),
    /MARKETPLACE_OFFER_VERSION/,
  );
  assert.throws(
    () =>
      verifyReleaseGate(
        validRecord(),
        { ...expected, cancellationPolicyVersion: '' },
        now,
      ),
    /MARKETPLACE_CANCELLATION_POLICY_VERSION/,
  );
});

test('blocks release without a fresh versioned acceptance smoke', () => {
  const record = validRecord();
  record.versionedAcceptance.status = 'blocked';

  assert.throws(
    () => verifyReleaseGate(record, expected, now),
    /Versioned document acceptance smoke/,
  );
});
