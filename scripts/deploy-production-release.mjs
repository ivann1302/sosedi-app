#!/usr/bin/env node

import { execFileSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';
import { runProductionSmoke } from './smoke-production-release.mjs';

export async function deployWithRollback({
  currentImage,
  previousImage,
  deployImage,
  smoke,
}) {
  try {
    await deployImage(currentImage);
    await smoke();
    return { status: 'deployed', image: currentImage };
  } catch (releaseError) {
    try {
      await deployImage(previousImage);
      await smoke();
    } catch (rollbackError) {
      throw new Error(
        `Release and rollback smoke failed: ${
          rollbackError instanceof Error
            ? rollbackError.message
            : 'unknown rollback error'
        }`,
        { cause: releaseError },
      );
    }
    throw new Error('Release smoke failed; previous digest restored', {
      cause: releaseError,
    });
  }
}

function run(command, args, env = process.env) {
  execFileSync(command, args, {
    cwd: resolve(new URL('..', import.meta.url).pathname),
    env,
    stdio: 'inherit',
    timeout: 180_000,
  });
}

function validateChangeId(value) {
  if (!/^[A-Za-z0-9._-]{1,64}$/.test(value ?? '')) {
    throw new Error('RELEASE_CHANGE_ID must be 1-64 safe characters');
  }
}

async function main() {
  const mode = process.argv[2] ?? 'deploy';
  const currentImage = process.env.BACKEND_IMAGE;
  const previousImage = process.env.PREVIOUS_BACKEND_IMAGE;
  const baseUrl = process.env.PRODUCTION_BASE_URL;
  validateChangeId(process.env.RELEASE_CHANGE_ID);
  if (!currentImage || !previousImage || !baseUrl) {
    throw new Error(
      'BACKEND_IMAGE, PREVIOUS_BACKEND_IMAGE and PRODUCTION_BASE_URL are required',
    );
  }

  run('node', ['./scripts/verify-release-gates.mjs']);
  run('./scripts/verify-production-image-references.sh', []);
  run('node', ['./scripts/verify-production-boundary.mjs']);

  const deployImage = async (image) => {
    run(
      'docker',
      [
        'compose',
        '-f',
        'docker-compose.yml',
        '-f',
        'docker-compose.production.yml',
        'up',
        '-d',
        '--no-deps',
        '--wait',
        '--wait-timeout',
        '120',
        'backend',
      ],
      { ...process.env, BACKEND_IMAGE: image },
    );
  };
  const smoke = () => runProductionSmoke({ baseUrl });

  if (mode === 'rollback') {
    await deployImage(previousImage);
    await smoke();
    process.stdout.write(
      `Manual rollback passed: change=${process.env.RELEASE_CHANGE_ID}\n`,
    );
    return;
  }
  if (mode !== 'deploy') {
    throw new Error('Mode must be deploy or rollback');
  }

  const result = await deployWithRollback({
    currentImage,
    previousImage,
    deployImage,
    smoke,
  });
  process.stdout.write(
    `Production release passed: change=${process.env.RELEASE_CHANGE_ID}, image=${result.image}\n`,
  );
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href
) {
  main().catch((error) => {
    process.stderr.write(
      `Production release gate failed: ${
        error instanceof Error ? error.message : 'unknown error'
      }\n`,
    );
    process.exitCode = 1;
  });
}
