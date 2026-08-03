#!/usr/bin/env node

import { execFileSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

function fail(message) {
  throw new Error(message);
}

function networkNames(service) {
  return Object.keys(service?.networks ?? {}).sort();
}

export function verifyProductionBoundary(config) {
  const services = config?.services ?? {};
  const backend = services.backend;
  const postgres = services.postgres;
  const redis = services.redis;
  if (!backend || !postgres || !redis) {
    fail('Production config must contain backend, postgres and redis');
  }

  for (const [name, service] of [
    ['postgres', postgres],
    ['redis', redis],
  ]) {
    if ((service.ports ?? []).length !== 0) {
      fail(`${name} must not publish host ports`);
    }
    if (networkNames(service).join(',') !== 'data') {
      fail(`${name} must use only the internal data network`);
    }
  }
  if (networkNames(backend).join(',') !== 'data,edge') {
    fail('backend must separate edge and data networks');
  }
  if (config.networks?.data?.internal !== true) {
    fail('data network must be internal');
  }
  if (
    backend.read_only !== true ||
    !backend.cap_drop?.includes('ALL') ||
    !backend.security_opt?.includes('no-new-privileges:true')
  ) {
    fail('backend container hardening is incomplete');
  }
  if (
    postgres.environment?.POSTGRES_PASSWORD !== undefined ||
    postgres.environment?.POSTGRES_PASSWORD_FILE !==
      '/run/secrets/postgres_password'
  ) {
    fail('PostgreSQL password must use a mounted secret file');
  }
  const redisCommand = (redis.command ?? []).join(' ');
  if (
    !redisCommand.includes('--aclfile /run/redis-auth/users.acl') ||
    !redisCommand.includes('user default off') ||
    !redisCommand.includes('user sosedi_runtime on') ||
    !redisCommand.includes('-CONFIG') ||
    !redisCommand.includes('-FLUSHALL') ||
    !redisCommand.includes('/run/secrets/redis_password')
  ) {
    fail('Redis must use the restricted mounted ACL credential');
  }
}

export function renderProductionConfig() {
  const placeholderDigest = 'a'.repeat(64);
  const output = execFileSync(
    'docker',
    [
      'compose',
      '-f',
      'docker-compose.yml',
      '-f',
      'docker-compose.production.yml',
      'config',
      '--format',
      'json',
    ],
    {
      cwd: resolve(new URL('..', import.meta.url).pathname),
      encoding: 'utf8',
      timeout: 10_000,
      env: {
        ...process.env,
        BACKEND_IMAGE: `registry.example.ru/sosedi/backend@sha256:${placeholderDigest}`,
        OCI_REGISTRY_PREFIX: 'registry.example.ru/sosedi',
        BACKEND_ENV_FILE: 'ops/environments/production.env.example',
        POSTGRES_DB: 'sosedi',
        POSTGRES_USER: 'sosedi_runtime',
        POSTGRES_PASSWORD_FILE: '/dev/null',
        REDIS_PASSWORD_FILE: '/dev/null',
      },
    },
  );
  return JSON.parse(output);
}

function main() {
  verifyProductionBoundary(renderProductionConfig());
  process.stdout.write(
    'Production DB/Redis network and credential boundary is closed\n',
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
      `Production boundary verification failed: ${
        error instanceof Error ? error.message : 'unknown error'
      }\n`,
    );
    process.exitCode = 1;
  }
}
