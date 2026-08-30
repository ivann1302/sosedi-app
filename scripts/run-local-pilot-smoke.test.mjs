import assert from 'node:assert/strict';
import test from 'node:test';
import { runLocalPilotSmoke } from './run-local-pilot-smoke.mjs';

const expectedSuccessCalls = [
  'make check',
  'make backend-test-e2e',
  'make mobile-screenshots',
  'make app-user-paths-check',
  'make test-infra-down',
];

test('runs pilot checks in order and cleans test infrastructure', async () => {
  const calls = [];

  await runLocalPilotSmoke(async (command, args) => {
    calls.push([command, ...args].join(' '));
  });

  assert.deepEqual(calls, expectedSuccessCalls);
});

test('stops at the first failed stage and still cleans infrastructure', async () => {
  const calls = [];
  const stageFailure = new Error('backend e2e failed');

  await assert.rejects(
    runLocalPilotSmoke(async (command, args) => {
      const invocation = [command, ...args].join(' ');
      calls.push(invocation);
      if (invocation === 'make backend-test-e2e') {
        throw stageFailure;
      }
    }),
    (error) => error === stageFailure,
  );

  assert.deepEqual(calls, [
    'make check',
    'make backend-test-e2e',
    'make test-infra-down',
  ]);
});

test('preserves the stage failure when cleanup also fails', async () => {
  const stageFailure = new Error('screenshot capture failed');

  await assert.rejects(
    runLocalPilotSmoke(async (command, args) => {
      const invocation = [command, ...args].join(' ');
      if (invocation === 'make mobile-screenshots') {
        throw stageFailure;
      }
      if (invocation === 'make test-infra-down') {
        throw new Error('cleanup failed');
      }
    }),
    (error) => error === stageFailure,
  );
});

test('reports cleanup failure after otherwise successful checks', async () => {
  const cleanupFailure = new Error('cleanup failed');

  await assert.rejects(
    runLocalPilotSmoke(async (command, args) => {
      if ([command, ...args].join(' ') === 'make test-infra-down') {
        throw cleanupFailure;
      }
    }),
    (error) => error === cleanupFailure,
  );
});
