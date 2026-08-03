import { createHash } from 'node:crypto';
import { lstatSync, readFileSync } from 'node:fs';
import { basename, dirname, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

import { verifyMobileReleaseConfig } from './verify-mobile-release-config.mjs';

export function verifyMobileReleaseArtifact(manifest, artifactBytes, expected) {
  verifyMobileReleaseConfig(expected);
  if (manifest?.schemaVersion !== 1) {
    throw new Error('Unsupported mobile release manifest schema');
  }
  if (!['appbundle', 'ipa'].includes(manifest.target)) {
    throw new Error('Invalid mobile release target');
  }
  const generatedAt = Date.parse(manifest.generatedAt);
  if (!Number.isFinite(generatedAt)) {
    throw new Error('Invalid mobile release manifest timestamp');
  }

  requireExact(manifest.appRelease, expected.APP_RELEASE, 'appRelease');
  requireExact(manifest.commitSha, expected.RELEASE_COMMIT_SHA, 'commitSha');
  requireExact(manifest.apiBaseUrl, expected.API_BASE_URL, 'apiBaseUrl');
  requireDocument(
    manifest.documents?.offer,
    expected.MARKETPLACE_OFFER_VERSION,
    expected.MARKETPLACE_OFFER_URL,
    'offer',
  );
  requireDocument(
    manifest.documents?.rentalRules,
    expected.MARKETPLACE_CANCELLATION_POLICY_VERSION,
    expected.MARKETPLACE_RENTAL_RULES_URL,
    'rentalRules',
  );
  requireDocument(
    manifest.documents?.privacy,
    expected.MARKETPLACE_PRIVACY_VERSION,
    expected.MARKETPLACE_PRIVACY_URL,
    'privacy',
  );

  const artifact = manifest.artifact;
  const expectedExtension = manifest.target === 'appbundle' ? '.aab' : '.ipa';
  if (
    typeof artifact?.file !== 'string' ||
    artifact.file !== basename(artifact.file) ||
    !artifact.file.endsWith(expectedExtension)
  ) {
    throw new Error('Invalid mobile artifact filename');
  }
  if (artifact.sizeBytes !== artifactBytes.byteLength) {
    throw new Error('Mobile artifact size mismatch');
  }
  const actualSha256 = createHash('sha256')
    .update(artifactBytes)
    .digest('hex');
  if (artifact.sha256 !== actualSha256) {
    throw new Error('Mobile artifact SHA-256 mismatch');
  }
}

function requireDocument(actual, version, url, name) {
  requireExact(actual?.version, version, `documents.${name}.version`);
  requireExact(actual?.url, url, `documents.${name}.url`);
}

function requireExact(actual, expected, name) {
  if (actual !== expected) {
    throw new Error(`Mobile release ${name} mismatch`);
  }
}

export function verifyMobileReleaseArtifactFiles(manifestPath, expected) {
  if (!manifestPath) {
    throw new Error('MOBILE_RELEASE_MANIFEST_PATH is required');
  }
  const resolvedManifestPath = resolve(manifestPath);
  const manifest = JSON.parse(readFileSync(resolvedManifestPath, 'utf8'));
  const artifactFile = manifest.artifact?.file;
  if (
    typeof artifactFile !== 'string' ||
    artifactFile !== basename(artifactFile)
  ) {
    throw new Error('Invalid mobile artifact filename');
  }
  const artifactPath = resolve(
    dirname(resolvedManifestPath),
    artifactFile,
  );
  if (lstatSync(artifactPath).isSymbolicLink()) {
    throw new Error('Mobile release artifact must not be a symlink');
  }
  verifyMobileReleaseArtifact(
    manifest,
    readFileSync(artifactPath),
    expected,
  );
  return manifest;
}

function main() {
  const manifest = verifyMobileReleaseArtifactFiles(
    process.env.MOBILE_RELEASE_MANIFEST_PATH,
    process.env,
  );
  process.stdout.write(
    `Mobile release artifact verified: ${manifest.target} ${manifest.artifact.sha256}\n`,
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
      `Mobile release artifact verification failed: ${
        error instanceof Error ? error.message : 'unknown error'
      }\n`,
    );
    process.exitCode = 1;
  }
}
