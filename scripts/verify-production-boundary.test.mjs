import assert from 'node:assert/strict';
import test from 'node:test';
import { verifyProductionBoundary } from './verify-production-boundary.mjs';

function validConfig() {
  return {
    networks: { data: { internal: true }, edge: {} },
    services: {
      backend: {
        networks: { data: null, edge: null },
        read_only: true,
        cap_drop: ['ALL'],
        security_opt: ['no-new-privileges:true'],
      },
      postgres: {
        networks: { data: null },
        environment: {
          POSTGRES_PASSWORD_FILE: '/run/secrets/postgres_password',
        },
      },
      redis: {
        networks: { data: null },
        command: [
          '/bin/sh',
          '-ceu',
          'user default off; user sosedi_runtime on; -CONFIG; -FLUSHALL; cat /run/secrets/redis_password; redis-server --aclfile /run/redis-auth/users.acl',
        ],
      },
    },
  };
}

test('accepts closed data services and hardened backend', () => {
  assert.doesNotThrow(() => verifyProductionBoundary(validConfig()));
});

test('rejects a published PostgreSQL port', () => {
  const config = validConfig();
  config.services.postgres.ports = [{ published: '5432', target: 5432 }];

  assert.throws(
    () => verifyProductionBoundary(config),
    /postgres must not publish host ports/,
  );
});

test('rejects Redis without authentication', () => {
  const config = validConfig();
  config.services.redis.command = ['redis-server'];

  assert.throws(
    () => verifyProductionBoundary(config),
    /Redis must use the restricted mounted ACL credential/,
  );
});
