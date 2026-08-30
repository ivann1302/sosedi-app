import { readFile, readdir } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const IMAGE_SOURCE_PATTERN = /<img\b[^>]*\bsrc=(['"])(.*?)\1[^>]*>/g;
const SAFE_SCREENSHOT_PATTERN = /^screenshots\/([a-zA-Z0-9][a-zA-Z0-9._-]*\.png)$/;

export async function verifyAppUserPaths({ htmlPath, screenshotsDir }) {
  const html = await readFile(htmlPath, 'utf8');
  const imageSources = [...html.matchAll(IMAGE_SOURCE_PATTERN)].map(
    (match) => match[2],
  );
  if (imageSources.length === 0) {
    throw new Error('App user-path map must reference at least one screenshot');
  }

  const unsafeSources = imageSources.filter(
    (source) => !SAFE_SCREENSHOT_PATTERN.test(source),
  );
  if (unsafeSources.length > 0) {
    throw new Error(`Unsafe image sources: ${unsafeSources.join(', ')}`);
  }

  const references = imageSources.map(
    (source) => SAFE_SCREENSHOT_PATTERN.exec(source)[1],
  );

  const entries = await readdir(screenshotsDir, { withFileTypes: true });
  const unsafeEntries = entries.filter(
    (entry) => entry.name.endsWith('.png') && !entry.isFile(),
  );
  if (unsafeEntries.length > 0) {
    throw new Error(
      `Screenshot entries must be regular files: ${unsafeEntries.map((entry) => entry.name).sort().join(', ')}`,
    );
  }
  const files = entries
    .filter((entry) => entry.isFile() && entry.name.endsWith('.png'))
    .map((entry) => entry.name)
    .sort();
  const referenceSet = new Set(references);
  const fileSet = new Set(files);
  const missing = references.filter((name) => !fileSet.has(name)).sort();
  if (missing.length > 0) {
    throw new Error(`Missing screenshot files: ${missing.join(', ')}`);
  }
  const unreferenced = files.filter((name) => !referenceSet.has(name));
  if (unreferenced.length > 0) {
    throw new Error(
      `Unreferenced screenshot files: ${unreferenced.join(', ')}`,
    );
  }

  return { references: references.length, files: files.length };
}

async function main() {
  const repositoryRoot = resolve(
    dirname(fileURLToPath(import.meta.url)),
    '..',
  );
  const result = await verifyAppUserPaths({
    htmlPath: join(repositoryRoot, 'docs', 'app-user-paths.html'),
    screenshotsDir: join(repositoryRoot, 'docs', 'screenshots'),
  });
  process.stdout.write(
    `App user-path map verified: references=${result.references}, files=${result.files}\n`,
  );
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href
) {
  void main().catch((error) => {
    const message = error instanceof Error ? error.message : 'Unknown error';
    process.stderr.write(`App user-path verification failed: ${message}\n`);
    process.exitCode = 1;
  });
}
