import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import {
  chmodSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import {
  buildMobileRelease,
  createMobileReleaseManifest,
  verifyReleaseSigning,
  verifyReleaseSource,
} from './build-mobile-release.mjs';

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

function recordingRunner(calls) {
  return (command, args, options) => {
    calls.push({ command, args, cwd: options.cwd });
    return { status: 0 };
  };
}

test('builds an app bundle with the exact validated dart defines', () => {
  const calls = [];

  const recorded = [];
  buildMobileRelease(
    'appbundle',
    valid,
    recordingRunner(calls),
    (...args) => recorded.push(args),
    () => {},
    () => {},
  );

  assert.equal(calls.length, 2);
  assert.deepEqual(calls[0].args, ['pub', 'get', '--enforce-lockfile']);
  assert.deepEqual(calls[1].args.slice(0, 4), [
    'build',
    'appbundle',
    '--release',
    '--no-pub',
  ]);
  assert.deepEqual(
    calls[1].args.slice(4, 6),
    ['--build-name=1.0.0', '--build-number=42'],
  );
  assert.deepEqual(
    calls[1].args.slice(6),
    Object.entries(valid)
      .map(([key, value]) => `--dart-define=${key}=${value}`)
      .filter(
        (value) => !value.startsWith('--dart-define=RELEASE_COMMIT_SHA='),
      ),
  );
  assert.equal(calls[0].cwd, calls[1].cwd);
  assert.equal(recorded.length, 1);
});

test('uses the locked CocoaPods install before an ipa build', () => {
  const calls = [];

  buildMobileRelease(
    'ipa',
    valid,
    recordingRunner(calls),
    () => {},
    () => {},
    () => {},
  );

  assert.equal(calls.length, 3);
  assert.equal(calls[1].command, 'pod');
  assert.deepEqual(calls[1].args, ['install', '--deployment']);
  assert.match(calls[1].cwd, /\/mobile\/ios$/u);
  assert.deepEqual(calls[2].args.slice(0, 4), [
    'build',
    'ipa',
    '--release',
    '--no-pub',
  ]);
});

test('rejects an unsafe config or target before invoking build tools', () => {
  const calls = [];
  const runner = recordingRunner(calls);

  assert.throws(
    () =>
      buildMobileRelease(
        'appbundle',
        { ...valid, API_BASE_URL: 'https://localhost:3000/api/v1' },
        runner,
      ),
    /clean HTTPS URL/u,
  );
  assert.throws(
    () => buildMobileRelease('apk', valid, runner),
    /target must be appbundle or ipa/u,
  );
  assert.equal(calls.length, 0);
});

test('stops after the first failed build command', () => {
  const calls = [];
  const runner = (command, args, options) => {
    calls.push({ command, args, cwd: options.cwd });
    return { status: 9 };
  };

  assert.throws(
    () =>
      buildMobileRelease(
        'appbundle',
        valid,
        runner,
        () => {},
        () => {},
        () => {},
      ),
    /failed with status 9/u,
  );
  assert.equal(calls.length, 1);
});

test('requires the declared commit and a clean worktree before build', () => {
  const cleanRunner = (_, args) => ({
    status: 0,
    stdout: args[0] === 'rev-parse' ? `${valid.RELEASE_COMMIT_SHA}\n` : '',
  });
  assert.doesNotThrow(() =>
    verifyReleaseSource(valid, '/repository', cleanRunner),
  );

  assert.throws(
    () =>
      verifyReleaseSource(valid, '/repository', (_, args) => ({
        status: 0,
        stdout: args[0] === 'rev-parse' ? `${'b'.repeat(40)}\n` : '',
      })),
    /does not match Git HEAD/u,
  );
  assert.throws(
    () =>
      verifyReleaseSource(valid, '/repository', (_, args) => ({
        status: 0,
        stdout:
          args[0] === 'rev-parse'
            ? `${valid.RELEASE_COMMIT_SHA}\n`
            : ' M mobile/lib/main.dart\n',
      })),
    /clean Git worktree/u,
  );
});

test('requires private Android release signing files', (t) => {
  const directory = mkdtempSync(join(tmpdir(), 'sosedi-android-signing-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const androidDirectory = join(directory, 'mobile/android');
  mkdirSync(androidDirectory, { recursive: true });
  const propertiesPath = join(androidDirectory, 'key.properties');
  const keystorePath = join(androidDirectory, 'upload.jks');
  writeFileSync(keystorePath, 'test-keystore');
  writeFileSync(
    propertiesPath,
    [
      'keyAlias=sosedi-upload',
      'keyPassword=test-key-password',
      'storeFile=upload.jks',
      'storePassword=test-store-password',
    ].join('\n'),
  );
  chmodSync(propertiesPath, 0o600);
  chmodSync(keystorePath, 0o600);

  assert.doesNotThrow(() =>
    verifyReleaseSigning('appbundle', join(directory, 'mobile')),
  );
  chmodSync(propertiesPath, 0o644);
  assert.throws(
    () => verifyReleaseSigning('appbundle', join(directory, 'mobile')),
    /must not be accessible by group or other/u,
  );
  assert.throws(
    () => verifyReleaseSigning('ipa', join(directory, 'missing-mobile')),
    /IOS_DEVELOPMENT_TEAM/u,
  );
});

test('requires matching App Store Connect export options for iOS', (t) => {
  const directory = mkdtempSync(join(tmpdir(), 'sosedi-ios-signing-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const mobileDirectory = join(directory, 'mobile');
  mkdirSync(mobileDirectory, { recursive: true });
  const exportOptionsPath = join(directory, 'ExportOptions.plist');
  writeFileSync(
    exportOptionsPath,
    [
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<plist version="1.0"><dict>',
      '<key>method</key><string>app-store-connect</string>',
      '<key>teamID</key><string>ABCDE12345</string>',
      '</dict></plist>',
    ].join('\n'),
  );
  chmodSync(exportOptionsPath, 0o600);

  expectIosSigningArgs(
    verifyReleaseSigning('ipa', mobileDirectory, {
      IOS_DEVELOPMENT_TEAM: 'ABCDE12345',
      IOS_EXPORT_OPTIONS_PLIST: exportOptionsPath,
    }),
    exportOptionsPath,
  );
  assert.throws(
    () =>
      verifyReleaseSigning('ipa', mobileDirectory, {
        IOS_DEVELOPMENT_TEAM: 'FGHIJ67890',
        IOS_EXPORT_OPTIONS_PLIST: exportOptionsPath,
      }),
    /teamID mismatch/u,
  );
});

function expectIosSigningArgs(actual, exportOptionsPath) {
  assert.deepEqual(actual, [
    `--export-options-plist=${exportOptionsPath}`,
  ]);
}

test('never assigns the Android debug key to release', () => {
  const gradle = readFileSync(
    new URL('../mobile/android/app/build.gradle.kts', import.meta.url),
    'utf8',
  );

  assert.doesNotMatch(gradle, /signingConfigs\.getByName\("debug"\)/u);
  assert.match(gradle, /signingConfigs\.findByName\("release"\)/u);
});

test('creates a secret-free checksum manifest bound to source and config', () => {
  const artifact = Buffer.from('signed-mobile-artifact');
  const manifest = createMobileReleaseManifest(
    'appbundle',
    valid,
    '/private/build/app-release.aab',
    artifact,
    new Date('2026-07-30T01:02:03.000Z'),
  );

  assert.deepEqual(manifest.artifact, {
    file: 'app-release.aab',
    sha256: createHash('sha256').update(artifact).digest('hex'),
    sizeBytes: artifact.byteLength,
  });
  assert.equal(manifest.commitSha, valid.RELEASE_COMMIT_SHA);
  assert.equal(
    manifest.documents.rentalRules.url,
    valid.MARKETPLACE_RENTAL_RULES_URL,
  );
  assert.equal(JSON.stringify(manifest).includes('/private/build'), false);
});
