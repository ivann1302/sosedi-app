import assert from 'node:assert/strict';
import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { verifyAppUserPaths } from './verify-app-user-paths.mjs';

const temporaryDirectories = [];

test.afterEach(async () => {
  await Promise.all(
    temporaryDirectories.splice(0).map((directory) =>
      rm(directory, { recursive: true, force: true }),
    ),
  );
});

test('accepts unique screenshot references with matching PNG files', async () => {
  const fixture = await createFixture(
    '<img src="screenshots/catalog.png"><img src="screenshots/item.png">',
    ['catalog.png', 'item.png'],
  );

  assert.deepEqual(await verifyAppUserPaths(fixture), {
    references: 2,
    files: 2,
  });
});

test('rejects a referenced screenshot that is missing on disk', async () => {
  const fixture = await createFixture(
    '<img src="screenshots/catalog.png"><img src="screenshots/item.png">',
    ['catalog.png'],
  );

  await assert.rejects(
    verifyAppUserPaths(fixture),
    /Missing screenshot files: item\.png/,
  );
});

test('allows one screen to participate in multiple user paths', async () => {
  const fixture = await createFixture(
    '<img src="screenshots/catalog.png"><img src="screenshots/catalog.png">',
    ['catalog.png'],
  );

  assert.deepEqual(await verifyAppUserPaths(fixture), {
    references: 2,
    files: 1,
  });
});

test('rejects unsafe image sources instead of following them', async () => {
  const fixture = await createFixture(
    '<img src="../private.png"><img src="https://example.test/item.png">',
    [],
  );

  await assert.rejects(
    verifyAppUserPaths(fixture),
    /Unsafe image sources/,
  );
});

test('rejects a PNG that is not linked from a user path', async () => {
  const fixture = await createFixture(
    '<img src="screenshots/catalog.png">',
    ['catalog.png', 'orphan.png'],
  );

  await assert.rejects(
    verifyAppUserPaths(fixture),
    /Unreferenced screenshot files: orphan\.png/,
  );
});

async function createFixture(html, screenshotFiles) {
  const directory = await mkdtemp(join(tmpdir(), 'sosedi-app-paths-'));
  temporaryDirectories.push(directory);
  const screenshotsDir = join(directory, 'screenshots');
  const htmlPath = join(directory, 'app-user-paths.html');
  await mkdir(screenshotsDir);
  await writeFile(htmlPath, html, 'utf8');
  await Promise.all(
    screenshotFiles.map((name) => writeFile(join(screenshotsDir, name), 'png')),
  );
  return { htmlPath, screenshotsDir };
}
