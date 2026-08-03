import assert from 'node:assert/strict';
import test from 'node:test';
import { deployWithRollback } from './deploy-production-release.mjs';

test('keeps the current image only after smoke passes', async () => {
  const deployed = [];
  const result = await deployWithRollback({
    currentImage: 'current',
    previousImage: 'previous',
    deployImage: async (image) => deployed.push(image),
    smoke: async () => undefined,
  });

  assert.deepEqual(deployed, ['current']);
  assert.deepEqual(result, { status: 'deployed', image: 'current' });
});

test('restores the previous image after release smoke failure', async () => {
  const deployed = [];
  let smokeCalls = 0;

  await assert.rejects(
    () =>
      deployWithRollback({
        currentImage: 'current',
        previousImage: 'previous',
        deployImage: async (image) => deployed.push(image),
        smoke: async () => {
          smokeCalls += 1;
          if (smokeCalls === 1) throw new Error('catalog failed');
        },
      }),
    /previous digest restored/,
  );
  assert.deepEqual(deployed, ['current', 'previous']);
});

test('reports a critical failure when rollback smoke also fails', async () => {
  await assert.rejects(
    () =>
      deployWithRollback({
        currentImage: 'current',
        previousImage: 'previous',
        deployImage: async () => undefined,
        smoke: async () => {
          throw new Error('not ready');
        },
      }),
    /Release and rollback smoke failed/,
  );
});
