#!/usr/bin/env node

import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

function fail(message) {
  throw new Error(message);
}

function envelope(body, name) {
  if (
    !body ||
    typeof body !== 'object' ||
    body.success !== true ||
    body.error !== null
  ) {
    fail(`${name} returned an invalid success envelope`);
  }
  return body.data;
}

async function fetchJson(fetchImpl, url) {
  const response = await fetchImpl(url, {
    headers: { accept: 'application/json', 'user-agent': 'sosedi-release-smoke' },
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) {
    fail(`${url.pathname} returned HTTP ${response.status}`);
  }
  return response.json();
}

function validateBaseUrl(value) {
  const baseUrl = new URL(value);
  if (
    baseUrl.protocol !== 'https:' ||
    baseUrl.username ||
    baseUrl.password ||
    baseUrl.pathname !== '/' ||
    baseUrl.search ||
    baseUrl.hash
  ) {
    fail('PRODUCTION_BASE_URL must be a credential-free HTTPS origin');
  }
  return baseUrl;
}

function sleep(milliseconds) {
  return new Promise((resolvePromise) => setTimeout(resolvePromise, milliseconds));
}

export async function runProductionSmoke({
  baseUrl,
  fetchImpl = fetch,
  readinessAttempts = 18,
  retryDelayMs = 5_000,
}) {
  const origin = validateBaseUrl(baseUrl);
  const live = envelope(
    await fetchJson(fetchImpl, new URL('/api/v1/health/live', origin)),
    'liveness',
  );
  if (live?.status !== 'ok') {
    fail('liveness is not ok');
  }

  let readinessError;
  for (let attempt = 0; attempt < readinessAttempts; attempt += 1) {
    try {
      const ready = envelope(
        await fetchJson(fetchImpl, new URL('/api/v1/health/ready', origin)),
        'readiness',
      );
      if (
        ready?.status !== 'ready' ||
        !['database', 'migrations', 'redis', 'clock'].every(
          (check) => ready.checks?.[check] === 'ok',
        )
      ) {
        fail('readiness checks are incomplete');
      }
      readinessError = undefined;
      break;
    } catch (error) {
      readinessError = error;
      if (attempt + 1 < readinessAttempts) {
        await sleep(retryDelayMs);
      }
    }
  }
  if (readinessError) {
    throw readinessError;
  }

  const [categoriesBody, itemsBody] = await Promise.all([
    fetchJson(fetchImpl, new URL('/api/v1/categories', origin)),
    fetchJson(fetchImpl, new URL('/api/v1/items?limit=1', origin)),
  ]);
  const categories = envelope(categoriesBody, 'categories');
  const items = envelope(itemsBody, 'items');
  if (!Array.isArray(categories) || !Array.isArray(items)) {
    fail('business smoke did not return catalog arrays');
  }

  return {
    hostname: origin.hostname,
    checks: ['liveness', 'readiness', 'categories', 'items'],
  };
}

async function main() {
  const baseUrl = process.env.PRODUCTION_BASE_URL;
  if (!baseUrl) {
    fail('PRODUCTION_BASE_URL is required');
  }
  const result = await runProductionSmoke({ baseUrl });
  process.stdout.write(
    `Production smoke passed for ${result.hostname}: ${result.checks.join(', ')}\n`,
  );
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href
) {
  main().catch((error) => {
    process.stderr.write(
      `Production smoke failed: ${
        error instanceof Error ? error.message : 'unknown error'
      }\n`,
    );
    process.exitCode = 1;
  });
}
