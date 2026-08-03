import assert from 'node:assert/strict';
import test from 'node:test';
import { runProductionSmoke } from './smoke-production-release.mjs';

function response(data, status = 200) {
  return new Response(
    JSON.stringify(
      status < 400
        ? { success: true, data, error: null }
        : { success: false, data: null, error: { code: 'FAILED' } },
    ),
    {
      status,
      headers: { 'content-type': 'application/json' },
    },
  );
}

function healthyFetch(url) {
  const path = url.pathname;
  if (path.endsWith('/health/live')) return response({ status: 'ok' });
  if (path.endsWith('/health/ready')) {
    return response({
      status: 'ready',
      checks: {
        database: 'ok',
        migrations: 'ok',
        redis: 'ok',
        clock: 'ok',
      },
    });
  }
  return response([]);
}

test('passes the required read-only production smoke', async () => {
  await assert.doesNotReject(() =>
    runProductionSmoke({
      baseUrl: 'https://api.sosedi.example',
      fetchImpl: healthyFetch,
      readinessAttempts: 1,
    }),
  );
});

test('rejects a readiness response without the clock check', async () => {
  await assert.rejects(
    () =>
      runProductionSmoke({
        baseUrl: 'https://api.sosedi.example',
        fetchImpl: (url) => {
          if (url.pathname.endsWith('/health/ready')) {
            return response({
              status: 'ready',
              checks: {
                database: 'ok',
                migrations: 'ok',
                redis: 'ok',
              },
            });
          }
          return healthyFetch(url);
        },
        readinessAttempts: 1,
      }),
    /readiness checks are incomplete/,
  );
});

test('rejects credentials or plaintext HTTP in the target URL', async () => {
  await assert.rejects(
    () =>
      runProductionSmoke({
        baseUrl: 'http://user:secret@api.sosedi.example',
        fetchImpl: healthyFetch,
        readinessAttempts: 1,
      }),
    /credential-free HTTPS origin/,
  );
});
