import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  assertStoredBackup,
  publishBackupSuccessMetric,
} from './postgres-backup';

describe('PostgreSQL backup object verification', () => {
  it('requires the expected encrypted size and checksum metadata', () => {
    expect(() =>
      assertStoredBackup(
        'primary',
        42,
        { encryptedsha256: 'abc123' },
        42,
        'abc123',
      ),
    ).not.toThrow();

    expect(() =>
      assertStoredBackup(
        'secondary',
        41,
        { encryptedsha256: 'abc123' },
        42,
        'abc123',
      ),
    ).toThrow('secondary');
    expect(() =>
      assertStoredBackup(
        'secondary',
        42,
        { encryptedsha256: 'different' },
        42,
        'abc123',
      ),
    ).toThrow('secondary');
  });

  it('atomically publishes the verified backup success timestamp', async () => {
    const directory = await mkdtemp(join(tmpdir(), 'sosedi-backup-metric-'));
    const metricPath = join(directory, 'sosedi_backup.prom');
    try {
      await publishBackupSuccessMetric(
        metricPath,
        new Date('2026-07-30T03:45:00.000Z'),
      );

      await expect(readFile(metricPath, 'utf8')).resolves.toBe(
        '# HELP sosedi_backup_last_success_timestamp_seconds Last verified encrypted dual-copy PostgreSQL backup.\n' +
          '# TYPE sosedi_backup_last_success_timestamp_seconds gauge\n' +
          'sosedi_backup_last_success_timestamp_seconds 1785383100\n',
      );
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  });

  it('rejects a non-explicit metrics target', async () => {
    await expect(
      publishBackupSuccessMetric(
        'backup.prom',
        new Date('2026-07-30T03:45:00.000Z'),
      ),
    ).rejects.toThrow('absolute sosedi_backup.prom path');
  });
});
