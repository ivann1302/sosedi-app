import assert from 'node:assert/strict';
import test from 'node:test';
import { verifyTimeSync } from './verify-time-sync.mjs';

test('accepts a synchronized UTC host', () => {
  assert.doesNotThrow(() =>
    verifyTimeSync({
      ntpEnabled: true,
      ntpSynchronized: true,
      timezone: 'UTC',
    }),
  );
});

test('rejects an unsynchronized host', () => {
  assert.throws(
    () =>
      verifyTimeSync({
        ntpEnabled: true,
        ntpSynchronized: false,
        timezone: 'UTC',
      }),
    /not synchronized/,
  );
});

test('rejects local timezone for production operations', () => {
  assert.throws(
    () =>
      verifyTimeSync({
        ntpEnabled: true,
        ntpSynchronized: true,
        timezone: 'Europe\/Moscow',
      }),
    /timezone must be UTC/,
  );
});
