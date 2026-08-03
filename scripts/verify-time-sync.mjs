#!/usr/bin/env node

import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

const UTC_TIMEZONES = new Set(['UTC', 'Etc/UTC']);

export function verifyTimeSync(status) {
  if (status.ntpEnabled !== true) {
    throw new Error('Host NTP synchronization is not enabled');
  }
  if (status.ntpSynchronized !== true) {
    throw new Error('Host clock is not synchronized');
  }
  if (!UTC_TIMEZONES.has(status.timezone)) {
    throw new Error(`Host timezone must be UTC, received ${status.timezone}`);
  }
}

function timedatectl(property) {
  return execFileSync(
    'timedatectl',
    ['show', `--property=${property}`, '--value'],
    { encoding: 'utf8', timeout: 5_000 },
  ).trim();
}

function readHostStatus() {
  try {
    return {
      ntpEnabled: timedatectl('NTP') === 'yes',
      ntpSynchronized: timedatectl('NTPSynchronized') === 'yes',
      timezone: timedatectl('Timezone'),
    };
  } catch (error) {
    throw new Error(
      `Unable to read systemd time status: ${
        error instanceof Error ? error.message : 'unknown error'
      }`,
    );
  }
}

function main() {
  const statusFileIndex = process.argv.indexOf('--status-file');
  const status =
    statusFileIndex >= 0
      ? JSON.parse(
          readFileSync(resolve(process.argv[statusFileIndex + 1]), 'utf8'),
        )
      : readHostStatus();
  verifyTimeSync(status);
  process.stdout.write(
    `Time sync ready: NTP enabled, synchronized, timezone ${status.timezone}\n`,
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
      `Time sync verification failed: ${
        error instanceof Error ? error.message : 'unknown error'
      }\n`,
    );
    process.exitCode = 1;
  }
}
