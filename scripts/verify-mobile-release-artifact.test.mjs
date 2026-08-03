import assert from 'node:assert/strict';
import {
  mkdtempSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import { createMobileReleaseManifest } from './build-mobile-release.mjs';
import {
  verifyMobileReleaseArtifact,
  verifyMobileReleaseArtifactFiles,
} from './verify-mobile-release-artifact.mjs';

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
const artifact = Buffer.from('signed-mobile-artifact');

function validManifest() {
  return createMobileReleaseManifest(
    'appbundle',
    valid,
    'app-release.aab',
    artifact,
    new Date('2026-07-30T01:02:03.000Z'),
  );
}

test('accepts the exact artifact, source and public config', () => {
  assert.doesNotThrow(() =>
    verifyMobileReleaseArtifact(validManifest(), artifact, valid),
  );
});

test('rejects changed artifact bytes and path traversal', () => {
  assert.throws(
    () =>
      verifyMobileReleaseArtifact(
        validManifest(),
        Buffer.from('changed-artifact'),
        valid,
      ),
    /size mismatch|SHA-256 mismatch/u,
  );

  const traversal = validManifest();
  traversal.artifact.file = '../app-release.aab';
  assert.throws(
    () => verifyMobileReleaseArtifact(traversal, artifact, valid),
    /artifact filename/u,
  );
});

test('rejects a manifest from another commit or document set', () => {
  const wrongCommit = validManifest();
  wrongCommit.commitSha = 'b'.repeat(40);
  assert.throws(
    () => verifyMobileReleaseArtifact(wrongCommit, artifact, valid),
    /commitSha mismatch/u,
  );

  const wrongRules = validManifest();
  wrongRules.documents.rentalRules.version = 'old-rules';
  assert.throws(
    () => verifyMobileReleaseArtifact(wrongRules, artifact, valid),
    /documents\.rentalRules\.version mismatch/u,
  );
});

test('reads only an adjacent regular artifact file', (t) => {
  const directory = mkdtempSync(join(tmpdir(), 'sosedi-mobile-artifact-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const artifactPath = join(directory, 'app-release.aab');
  const manifestPath = join(directory, 'sosedi-release-manifest.json');
  writeFileSync(artifactPath, artifact);
  writeFileSync(manifestPath, JSON.stringify(validManifest()));

  assert.doesNotThrow(() =>
    verifyMobileReleaseArtifactFiles(manifestPath, valid),
  );

  const symlinkPath = join(directory, 'linked-release.aab');
  symlinkSync(artifactPath, symlinkPath);
  const symlinkManifest = validManifest();
  symlinkManifest.artifact.file = 'linked-release.aab';
  writeFileSync(manifestPath, JSON.stringify(symlinkManifest));
  assert.throws(
    () => verifyMobileReleaseArtifactFiles(manifestPath, valid),
    /must not be a symlink/u,
  );
});
