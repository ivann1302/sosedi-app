import { access, readFile } from 'node:fs/promises';
import { join } from 'node:path';

const routes = [
  '/',
  '/documents/',
  '/documents/offer/draft-2026-07-29/',
  '/documents/rental-rules/draft-2026-07-29/',
  '/documents/privacy-consent/draft-2026-07-29/',
  '/documents/prohibited-items/2026-07-27.1/',
  '/support/',
  '/account-deletion/',
];

const outputFor = (route) =>
  route === '/' ? 'dist/index.html' : join('dist', route, 'index.html');

const routeOutputs = new Set(routes.map(outputFor));
const publicSupportHref = 'mailto:sosedi.rs@yandex.ru';
for (const route of routes) {
  const output = outputFor(route);
  const html = await readFile(output, 'utf8');
  if (!html.includes('<html lang="ru">')) {
    throw new Error(`${route} has no Russian language declaration`);
  }
  if (
    /<(form|script)\b/i.test(html) ||
    /google-analytics|appmetrica|metrika/i.test(html)
  ) {
    throw new Error(`${route} contains a form, script or analytics integration`);
  }

  if (
    ['/support/', '/account-deletion/'].includes(route) &&
    !html.includes(`href="${publicSupportHref}"`)
  ) {
    throw new Error(`${route} has no approved public support contact`);
  }

  for (const [, href] of html.matchAll(/href="(\/[^"#?]*)"/g)) {
    if (href.startsWith('/_astro/') || /\.[a-z0-9]+$/i.test(href)) {
      await access(join('dist', href.slice(1)));
      continue;
    }
    const normalized = href.endsWith('/') ? href : `${href}/`;
    const linkedOutput = outputFor(normalized);
    if (!routeOutputs.has(linkedOutput)) {
      throw new Error(`${route} links to missing internal route ${href}`);
    }
  }
}

const headers = await readFile('dist/_headers', 'utf8');
for (const required of [
  'Content-Security-Policy',
  "script-src 'none'",
  "connect-src 'none'",
  "form-action 'none'",
  'X-Content-Type-Options',
  'Permissions-Policy',
]) {
  if (!headers.includes(required)) {
    throw new Error(`Missing required security header: ${required}`);
  }
}

console.log(`Public web smoke passed: ${routes.length} routes`);
