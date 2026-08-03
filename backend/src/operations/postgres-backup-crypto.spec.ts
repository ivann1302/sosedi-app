import { randomBytes } from 'node:crypto';
import { mkdtemp, open, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  decryptBackupFile,
  encryptBackupFile,
  parseBackupKey,
} from './postgres-backup-crypto';

describe('PostgreSQL backup encryption', () => {
  it('round-trips an authenticated encrypted backup', async () => {
    const directory = await mkdtemp(join(tmpdir(), 'sosedi-backup-test-'));
    const source = join(directory, 'source.dump');
    const encrypted = join(directory, 'backup.enc');
    const restored = join(directory, 'restored.dump');
    const payload = randomBytes(64 * 1024);
    const key = randomBytes(32);

    try {
      await writeFile(source, payload);
      await encryptBackupFile(source, encrypted, key);
      await decryptBackupFile(encrypted, restored, key);

      await expect(readFile(restored)).resolves.toEqual(payload);
      expect(await readFile(encrypted)).not.toContain(payload);
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  });

  it('rejects a key that is not exactly 32 base64 bytes', () => {
    expect(() => parseBackupKey(Buffer.alloc(31).toString('base64'))).toThrow(
      '32 bytes',
    );
  });

  it('rejects a modified encrypted backup', async () => {
    const directory = await mkdtemp(join(tmpdir(), 'sosedi-backup-test-'));
    const source = join(directory, 'source.dump');
    const encrypted = join(directory, 'backup.enc');
    const restored = join(directory, 'restored.dump');
    const key = randomBytes(32);

    try {
      await writeFile(source, randomBytes(1024));
      await encryptBackupFile(source, encrypted, key);
      const handle = await open(encrypted, 'r+');
      try {
        await handle.write(Buffer.from([0xff]), 0, 1, 32);
      } finally {
        await handle.close();
      }

      await expect(
        decryptBackupFile(encrypted, restored, key),
      ).rejects.toThrow();
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  });
});
