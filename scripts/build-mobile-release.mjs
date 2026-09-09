import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import {
  chmodSync,
  lstatSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  rmSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import { basename, dirname, resolve } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath, pathToFileURL } from 'node:url';

import {
  mobileReleaseDartDefineArgs,
  parseMobileAppRelease,
} from './verify-mobile-release-config.mjs';

const supportedTargets = new Set(['appbundle', 'ipa']);
const repositoryRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');

export function buildMobileRelease(
  target,
  config,
  runner = spawnSync,
  recorder = writeMobileReleaseManifest,
  sourceVerifier = verifyReleaseSource,
  signingVerifier = verifyReleaseSigning,
) {
  if (!supportedTargets.has(target)) {
    throw new Error('target must be appbundle or ipa');
  }

  const dartDefineArgs = mobileReleaseDartDefineArgs(config);
  const releaseVersion = parseMobileAppRelease(config.APP_RELEASE);
  const mobileDirectory = resolve(repositoryRoot, 'mobile');
  const signingArgs = signingVerifier(target, mobileDirectory, config) ?? [];
  sourceVerifier(config, repositoryRoot);

  run(runner, 'flutter', ['pub', 'get', '--enforce-lockfile'], mobileDirectory);
  if (target === 'ipa') {
    run(
      runner,
      'pod',
      ['install', '--deployment'],
      resolve(mobileDirectory, 'ios'),
    );
  }
  withTilesKey(config.YANDEX_TILES_API_KEY, (tilesArgs) => {
    run(
      runner,
      'flutter',
      [
        'build',
        target,
        '--release',
        '--no-pub',
        `--build-name=${releaseVersion.buildName}`,
        `--build-number=${releaseVersion.buildNumber}`,
        ...signingArgs,
        ...dartDefineArgs,
        ...tilesArgs,
      ],
      mobileDirectory,
    );
  });
  return recorder(target, config, mobileDirectory);
}

function withTilesKey(key, build) {
  if (key === undefined || key === '') return build([]);
  if (typeof key !== 'string' || /\s/u.test(key)) {
    throw new Error('YANDEX_TILES_API_KEY must be a string without whitespace');
  }
  const directory = mkdtempSync(resolve(tmpdir(), 'sosedi-tiles-'));
  try {
    const path = resolve(directory, 'dart-defines.json');
    writeFileSync(path, JSON.stringify({ YANDEX_TILES_API_KEY: key }), {
      encoding: 'utf8',
      mode: 0o600,
      flag: 'wx',
    });
    return build([`--dart-define-from-file=${path}`]);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
}

export function buildMobileTilesSmoke(config, runner = spawnSync) {
  if (
    typeof config.YANDEX_TILES_API_KEY !== 'string' ||
    !config.YANDEX_TILES_API_KEY.trim()
  ) {
    throw new Error('YANDEX_TILES_API_KEY is required for the Tiles smoke build');
  }
  const mobileDirectory = resolve(repositoryRoot, 'mobile');
  withTilesKey(config.YANDEX_TILES_API_KEY, (tilesArgs) => {
    run(runner, 'flutter', ['pub', 'get', '--enforce-lockfile'], mobileDirectory);
    run(
      runner,
      'flutter',
      ['build', 'apk', '--debug', '--no-pub', ...tilesArgs],
      mobileDirectory,
    );
  });
}

export function verifyReleaseSigning(target, mobileDirectory, config = {}) {
  if (target === 'ipa') {
    return verifyIosReleaseSigning(mobileDirectory, config);
  }
  const propertiesPath = resolve(mobileDirectory, 'android/key.properties');
  requirePrivateRegularFile(propertiesPath, 'Android key.properties');
  const properties = parseProperties(readFileSync(propertiesPath, 'utf8'));
  for (const name of [
    'keyAlias',
    'keyPassword',
    'storeFile',
    'storePassword',
  ]) {
    if (!properties.get(name)) {
      throw new Error(`Missing Android release signing property: ${name}`);
    }
  }
  if (!/^[A-Za-z0-9._-]{1,128}$/u.test(properties.get('keyAlias'))) {
    throw new Error('Invalid Android release key alias');
  }
  const keystorePath = resolve(
    dirname(propertiesPath),
    properties.get('storeFile'),
  );
  requirePrivateRegularFile(keystorePath, 'Android release keystore');
  return [];
}

function verifyIosReleaseSigning(mobileDirectory, config) {
  const teamId = config.IOS_DEVELOPMENT_TEAM;
  if (!/^[A-Z0-9]{10}$/u.test(teamId ?? '')) {
    throw new Error('IOS_DEVELOPMENT_TEAM must be a 10-character Team ID');
  }
  if (!config.IOS_EXPORT_OPTIONS_PLIST) {
    throw new Error('IOS_EXPORT_OPTIONS_PLIST is required');
  }
  const exportOptionsPath = resolve(
    mobileDirectory,
    config.IOS_EXPORT_OPTIONS_PLIST,
  );
  requirePrivateRegularFile(exportOptionsPath, 'iOS ExportOptions.plist');
  const exportOptions = readFileSync(exportOptionsPath, 'utf8');
  if (
    !new RegExp(
      `<key>\\s*teamID\\s*</key>\\s*<string>\\s*${teamId}\\s*</string>`,
      'u',
    ).test(exportOptions)
  ) {
    throw new Error('iOS ExportOptions.plist teamID mismatch');
  }
  if (
    !/<key>\s*method\s*<\/key>\s*<string>\s*app-store-connect\s*<\/string>/u.test(
      exportOptions,
    )
  ) {
    throw new Error('iOS export method must be app-store-connect');
  }
  return [`--export-options-plist=${exportOptionsPath}`];
}

function parseProperties(contents) {
  const properties = new Map();
  for (const line of contents.split(/\r?\n/u)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) {
      continue;
    }
    const separator = trimmed.indexOf('=');
    if (separator <= 0) {
      throw new Error('Invalid Android key.properties format');
    }
    properties.set(
      trimmed.slice(0, separator).trim(),
      trimmed.slice(separator + 1).trim(),
    );
  }
  return properties;
}

function requirePrivateRegularFile(path, name) {
  const stat = lstatSync(path);
  if (stat.isSymbolicLink() || !stat.isFile()) {
    throw new Error(`${name} must be a regular file`);
  }
  if ((stat.mode & 0o077) !== 0) {
    throw new Error(`${name} must not be accessible by group or other`);
  }
}

export function verifyReleaseSource(config, cwd, runner = spawnSync) {
  const head = runCapture(runner, ['rev-parse', '--verify', 'HEAD'], cwd);
  if (head.trim() !== config.RELEASE_COMMIT_SHA) {
    throw new Error('RELEASE_COMMIT_SHA does not match Git HEAD');
  }
  const status = runCapture(
    runner,
    ['status', '--porcelain=v1', '--untracked-files=all'],
    cwd,
  );
  if (status.trim()) {
    throw new Error('Mobile release requires a clean Git worktree');
  }
}

export function createMobileReleaseManifest(
  target,
  config,
  artifactFile,
  artifactBytes,
  generatedAt = new Date(),
) {
  const dartDefineArgs = mobileReleaseDartDefineArgs(config);
  if (!supportedTargets.has(target) || dartDefineArgs.length === 0) {
    throw new Error('Cannot record an invalid mobile release');
  }
  return {
    schemaVersion: 1,
    target,
    generatedAt: generatedAt.toISOString(),
    appRelease: config.APP_RELEASE,
    commitSha: config.RELEASE_COMMIT_SHA,
    artifact: {
      file: basename(artifactFile),
      sha256: createHash('sha256').update(artifactBytes).digest('hex'),
      sizeBytes: artifactBytes.byteLength,
    },
    apiBaseUrl: config.API_BASE_URL,
    documents: {
      offer: {
        version: config.MARKETPLACE_OFFER_VERSION,
        url: config.MARKETPLACE_OFFER_URL,
      },
      rentalRules: {
        version: config.MARKETPLACE_CANCELLATION_POLICY_VERSION,
        url: config.MARKETPLACE_RENTAL_RULES_URL,
      },
      privacy: {
        version: config.MARKETPLACE_PRIVACY_VERSION,
        url: config.MARKETPLACE_PRIVACY_URL,
      },
    },
  };
}

function writeMobileReleaseManifest(target, config, mobileDirectory) {
  const artifactPath = findArtifact(target, mobileDirectory);
  if (!statSync(artifactPath).isFile()) {
    throw new Error('Flutter release artifact is not a regular file');
  }
  const manifest = createMobileReleaseManifest(
    target,
    config,
    artifactPath,
    readFileSync(artifactPath),
  );
  const manifestPath = resolve(
    dirname(artifactPath),
    'sosedi-release-manifest.json',
  );
  writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, {
    encoding: 'utf8',
    mode: 0o600,
  });
  chmodSync(manifestPath, 0o600);
  process.stdout.write(`Mobile release manifest: ${manifestPath}\n`);
  return manifestPath;
}

function findArtifact(target, mobileDirectory) {
  if (target === 'appbundle') {
    return resolve(
      mobileDirectory,
      'build/app/outputs/bundle/release/app-release.aab',
    );
  }
  const ipaDirectory = resolve(mobileDirectory, 'build/ios/ipa');
  const ipaFiles = readdirSync(ipaDirectory)
    .filter((name) => name.endsWith('.ipa'))
    .sort();
  if (ipaFiles.length !== 1) {
    throw new Error('Expected exactly one IPA artifact in build/ios/ipa');
  }
  return resolve(ipaDirectory, ipaFiles[0]);
}

function run(runner, command, args, cwd) {
  const result = runner(command, args, { cwd, stdio: 'inherit' });
  if (result.error) {
    throw result.error;
  }
  if (result.status !== 0) {
    throw new Error(
      `${command} ${args.slice(0, 2).join(' ')} failed with status ${
        result.status ?? 'unknown'
      }`,
    );
  }
}

function runCapture(runner, args, cwd) {
  const result = runner('git', args, {
    cwd,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  if (result.error) {
    throw result.error;
  }
  if (result.status !== 0 || typeof result.stdout !== 'string') {
    throw new Error(`git ${args.slice(0, 2).join(' ')} failed`);
  }
  return result.stdout;
}

function main() {
  const target = process.argv[2];
  if (target === 'tiles-smoke') {
    buildMobileTilesSmoke(process.env);
    process.stdout.write('Mobile Tiles debug smoke build completed\n');
    return;
  }
  const manifestPath = buildMobileRelease(target, process.env);
  process.stdout.write(
    `Mobile ${target} release build completed: ${manifestPath}\n`,
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
      `Mobile release build failed: ${
        error instanceof Error ? error.message : 'unknown error'
      }\n`,
    );
    process.exitCode = 1;
  }
}
