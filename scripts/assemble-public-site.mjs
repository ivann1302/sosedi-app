import { cp, mkdir, readdir, stat, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const [landingArgument, outputArgument] = process.argv.slice(2);
if (!landingArgument || !outputArgument) {
  throw new Error('Usage: node scripts/assemble-public-site.mjs <landing-out> <new-output-dir>');
}
const landing = resolve(landingArgument);
const output = resolve(outputArgument);
const astro = new URL('../public-web/dist/', import.meta.url);
const shared = ['documents', 'support', 'account-deletion', '_astro', 'fonts', 'logo'];
const landingFiles = await readdir(landing);
for (const name of shared) {
  if (landingFiles.includes(name)) throw new Error(`Landing/Astro path collision: ${name}`);
  await stat(new URL(name, astro));
}
await stat(resolve(landing, 'index.html'));
await stat(resolve(landing, 'business/index.html'));
// Fail on an existing destination; never erase a previous preview/release.
await mkdir(output);
for (const name of landingFiles) {
  if (name.startsWith('.') || ['_headers', 'robots.txt'].includes(name)) continue;
  await cp(resolve(landing, name), resolve(output, name), { recursive: true });
}
for (const name of shared) {
  await cp(new URL(name, astro), resolve(output, name), { recursive: true });
}
await writeFile(resolve(output, 'robots.txt'), 'User-agent: *\nDisallow: /\n');
console.log(`Public preview assembled: ${output}`);
