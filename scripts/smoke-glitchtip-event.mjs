import { randomUUID } from 'node:crypto';

const dsn = process.env.GLITCHTIP_DSN ?? '';
const environment = process.env.GLITCHTIP_SMOKE_ENVIRONMENT ?? 'staging';
const release = process.env.GLITCHTIP_SMOKE_RELEASE ?? '';
const dryRun = process.env.GLITCHTIP_SMOKE_DRY_RUN === 'true';

function fail(message) {
  process.stderr.write(`${message}\n`);
  process.exit(2);
}

let dsnUrl;
try {
  dsnUrl = new URL(dsn);
} catch {
  fail('GLITCHTIP_DSN must be a valid URL');
}

if (
  dsnUrl.protocol !== 'https:' ||
  !dsnUrl.username ||
  !dsnUrl.hostname ||
  dsnUrl.hostname === 'sentry.io' ||
  dsnUrl.hostname.endsWith('.sentry.io') ||
  dsnUrl.hostname === 'app.glitchtip.com'
) {
  fail('GLITCHTIP_DSN must point to self-hosted HTTPS GlitchTip');
}
if (!release) {
  fail('GLITCHTIP_SMOKE_RELEASE is required');
}

const pathParts = dsnUrl.pathname.split('/').filter(Boolean);
const projectId = pathParts.pop();
if (!projectId || !/^\d+$/.test(projectId)) {
  fail('GLITCHTIP_DSN must end with a numeric project ID');
}
const basePath = pathParts.length === 0 ? '' : `/${pathParts.join('/')}`;
const eventId = randomUUID().replaceAll('-', '');
const payload = {
  event_id: eventId,
  timestamp: new Date().toISOString(),
  platform: 'other',
  level: 'info',
  logger: 'sosedi.release-smoke',
  message: 'sosedi-glitchtip-release-smoke',
  environment,
  release,
  tags: {
    contains_pii: 'false',
    smoke: 'true',
  },
  extra: {
    check: 'transport-environment-release-alert',
  },
};

if (!dryRun) {
  const endpoint = new URL(
    `${basePath}/api/${projectId}/store/`,
    dsnUrl.origin,
  );
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-sentry-auth':
        `Sentry sentry_version=7, sentry_key=${dsnUrl.username}, sentry_client=sosedi-smoke/1.0`,
    },
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    fail(`GlitchTip rejected the smoke event with HTTP ${response.status}`);
  }
}

process.stdout.write(
  `GlitchTip smoke event accepted: event_id=${eventId} environment=${environment} release=${release} dry_run=${dryRun}\n`,
);
