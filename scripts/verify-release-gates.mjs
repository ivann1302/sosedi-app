#!/usr/bin/env node

import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';
import { parseEnv } from './environment-isolation.mjs';

const DAY_MS = 24 * 60 * 60 * 1000;

function fail(message) {
  throw new Error(message);
}

function timestamp(value, name) {
  const parsed = Date.parse(value);
  if (!Number.isFinite(parsed)) fail(`${name} must be an ISO timestamp`);
  return parsed;
}

function fresh(value, name, now, maxAgeMs) {
  const parsed = timestamp(value, name);
  if (parsed > now.getTime() + 5 * 60 * 1000) {
    fail(`${name} must not be in the future`);
  }
  if (now.getTime() - parsed > maxAgeMs) {
    fail(`${name} evidence is stale`);
  }
}

function reference(value, name) {
  if (
    typeof value !== 'string' ||
    value.length < 3 ||
    /replace|example|todo|pending|blocked/i.test(value)
  ) {
    fail(`${name} must reference approved evidence`);
  }
}

function approvedDocumentVersion(value, name) {
  reference(value, name);
  if (
    !/^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/.test(value) ||
    value.toLowerCase().includes('draft')
  ) {
    fail(`${name} must be an approved non-draft version`);
  }
}

function sha256(value, name) {
  if (typeof value !== 'string' || !/^[a-f0-9]{64}$/.test(value)) {
    fail(`${name} must be a lowercase SHA-256`);
  }
}

function positiveIntegerAtMost(value, maximum, name) {
  if (!Number.isInteger(value) || value <= 0 || value > maximum) {
    fail(`${name} must be an integer between 1 and ${maximum}`);
  }
}

function publicHttpsUrl(value, name) {
  let url;
  try {
    url = new URL(value);
  } catch {
    fail(`${name} must be a valid public HTTPS URL`);
  }
  if (
    url.protocol !== 'https:' ||
    url.username ||
    url.password ||
    url.search ||
    url.hash ||
    !isPublicHostname(url.hostname)
  ) {
    fail(`${name} must be a valid public HTTPS URL`);
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

function atMost(value, maximum, name) {
  if (!Number.isFinite(value) || value < 0 || value > maximum) {
    fail(`${name} must be between 0 and ${maximum}`);
  }
}

export function verifyReleaseGate(record, expected, now = new Date()) {
  if (record?.schemaVersion !== 1) fail('Unsupported release gate schema');
  if (!/^[A-Za-z0-9._-]{1,64}$/.test(record.releaseId ?? '')) {
    fail('Invalid release ID');
  }
  if (!/^[a-f0-9]{40}$|^[a-f0-9]{64}$/.test(record.commitSha ?? '')) {
    fail('Invalid release commit');
  }
  if (!/@sha256:[a-f0-9]{64}$/.test(record.backendImage ?? '')) {
    fail('Invalid backend manifest digest');
  }
  if (record.releaseId !== expected.releaseId) fail('Release ID mismatch');
  if (record.commitSha !== expected.commitSha) fail('Release commit mismatch');
  if (record.backendImage !== expected.backendImage) {
    fail('Release backend image mismatch');
  }
  fresh(record.generatedAt, 'generatedAt', now, DAY_MS);

  if (
    record.ci?.status !== 'passed' ||
    record.ci?.commitSha !== expected.commitSha
  ) {
    fail('CI must pass for the exact release commit');
  }
  if (record.p0?.status !== 'passed' || record.p0?.openFindings !== 0) {
    fail('Open P0 security/privacy findings block release');
  }
  fresh(record.p0?.checkedAt, 'p0.checkedAt', now, DAY_MS);

  if (
    record.restore?.status !== 'passed' ||
    record.restore?.postgresRestored !== true ||
    record.restore?.s3ObjectsRestored !== true
  ) {
    fail('Production-like PostgreSQL and S3 restore evidence is incomplete');
  }
  atMost(record.restore.rpoHours, 6, 'restore.rpoHours');
  atMost(record.restore.postgresRtoHours, 4, 'restore.postgresRtoHours');
  atMost(record.restore.s3RtoHours, 8, 'restore.s3RtoHours');
  sha256(record.restore?.s3Sample?.sha256, 'restore.s3Sample.sha256');
  sha256(
    record.restore?.s3Sample?.sourceKeySha256,
    'restore.s3Sample.sourceKeySha256',
  );
  positiveIntegerAtMost(
    record.restore?.s3Sample?.sizeBytes,
    20 * 1024 * 1024,
    'restore.s3Sample.sizeBytes',
  );
  reference(
    record.restore?.s3Sample?.targetRef,
    'restore.s3Sample.targetRef',
  );
  fresh(record.restore?.completedAt, 'restore.completedAt', now, 90 * DAY_MS);
  reference(record.restore?.evidenceRef, 'restore.evidenceRef');

  if (record.marketplaceLegalSafety?.status !== 'accepted') {
    fail('Marketplace legal/safety gate blocks release');
  }
  const versionedDocuments = [
    'offer',
    'rentalRules',
    'privacy',
    'prohibitedItems',
  ];
  for (const document of versionedDocuments) {
    approvedDocumentVersion(
      record.marketplaceLegalSafety?.documents?.[document],
      `marketplaceLegalSafety.documents.${document}`,
    );
  }
  if (
    expected.marketplaceOfferVersion !==
    record.marketplaceLegalSafety.documents.offer
  ) {
    fail('MARKETPLACE_OFFER_VERSION must match the approved offer version');
  }
  if (
    expected.cancellationPolicyVersion !==
    record.marketplaceLegalSafety.documents.rentalRules
  ) {
    fail(
      'MARKETPLACE_CANCELLATION_POLICY_VERSION must match the approved rental rules version',
    );
  }
  reference(
    record.marketplaceLegalSafety?.approvalRef,
    'marketplaceLegalSafety.approvalRef',
  );
  if (record.publicLinks?.status !== 'passed') {
    fail('Public legal/support link smoke blocks release');
  }
  fresh(record.publicLinks?.checkedAt, 'publicLinks.checkedAt', now, DAY_MS);
  for (const name of [
    ...versionedDocuments,
    'support',
    'accountDeletion',
  ]) {
    const url = publicHttpsUrl(
      record.publicLinks?.urls?.[name],
      `publicLinks.urls.${name}`,
    );
    if (
      versionedDocuments.includes(name) &&
      !url.pathname
        .split('/')
        .filter(Boolean)
        .includes(record.marketplaceLegalSafety.documents[name])
    ) {
      fail(`publicLinks.urls.${name} must contain the approved document version`);
    }
  }
  if (record.versionedAcceptance?.status !== 'passed') {
    fail('Versioned document acceptance smoke blocks release');
  }
  fresh(
    record.versionedAcceptance?.checkedAt,
    'versionedAcceptance.checkedAt',
    now,
    DAY_MS,
  );
  reference(
    record.versionedAcceptance?.evidenceRef,
    'versionedAcceptance.evidenceRef',
  );

  if (
    record.admin?.mfaSmoke !== 'passed' ||
    record.admin?.operatorSmoke !== 'passed' ||
    record.admin?.auditSmoke !== 'passed'
  ) {
    fail('Admin MFA/operator/audit smoke blocks release');
  }
  fresh(record.admin?.checkedAt, 'admin.checkedAt', now, DAY_MS);

  if (expected.paymentScenario !== 'PAY_ON_HANDOVER') {
    fail('Production payment scenario must be PAY_ON_HANDOVER');
  }
  if (record.payment?.scenario !== expected.paymentScenario) {
    fail('Payment scenario mismatch');
  }
  if (record.payment?.legalGate !== 'not-applicable') {
    fail('PAY_ON_HANDOVER payment must be not-applicable');
  }

  if (record.kyc?.mode === 'disabled') {
    if (record.kyc?.legalGate !== 'not-applicable') {
      fail('Disabled KYC mode must be not-applicable');
    }
  } else {
    if (
      !['provider-managed', 'local'].includes(record.kyc?.mode) ||
      record.kyc?.legalGate !== 'accepted'
    ) {
      fail('Enabled KYC legal gate blocks release');
    }
    reference(record.kyc?.adrRef, 'kyc.adrRef');
    reference(record.kyc?.approvalRef, 'kyc.approvalRef');
  }

  reference(record.approvals?.productOwner, 'approvals.productOwner');
  reference(record.approvals?.legalOwner, 'approvals.legalOwner');
}

function main() {
  const path = process.env.RELEASE_GATE_FILE;
  const backendEnvPath = process.env.BACKEND_ENV_FILE;
  if (!path || !backendEnvPath) {
    fail('RELEASE_GATE_FILE and BACKEND_ENV_FILE are required');
  }
  const record = JSON.parse(readFileSync(path, 'utf8'));
  const backendEnv = parseEnv(readFileSync(backendEnvPath, 'utf8'));
  verifyReleaseGate(record, {
    releaseId: process.env.RELEASE_CHANGE_ID,
    commitSha: process.env.RELEASE_COMMIT_SHA,
    backendImage: process.env.BACKEND_IMAGE,
    paymentScenario: backendEnv.get('PAYMENT_SCENARIO'),
    marketplaceOfferVersion: backendEnv.get('MARKETPLACE_OFFER_VERSION'),
    cancellationPolicyVersion: backendEnv.get(
      'MARKETPLACE_CANCELLATION_POLICY_VERSION',
    ),
  });
  process.stdout.write(
    `Release gates passed: ${record.releaseId} ${record.commitSha}\n`,
  );
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href
) {
  try {
    main();
  } catch (error) {
    process.stderr.write(
      `Release gate verification failed: ${
        error instanceof Error ? error.message : 'unknown error'
      }\n`,
    );
    process.exitCode = 1;
  }
}
