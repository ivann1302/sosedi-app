import {
  DeleteObjectsCommand,
  HeadObjectCommand,
  ListObjectsV2Command,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { createHash, randomUUID } from 'node:crypto';
import { createReadStream } from 'node:fs';
import { chmod, mkdtemp, rename, rm, stat, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { basename, dirname, isAbsolute, join } from 'node:path';
import { spawn } from 'node:child_process';
import { encryptBackupFile, parseBackupKey } from './postgres-backup-crypto';

const RETENTION_DAYS = 35;
const BACKUP_PREFIX = 'postgresql/';

type BackupDestination = {
  name: 'primary' | 'secondary';
  endpoint: string;
  bucket: string;
  client: S3Client;
};

async function main(): Promise<void> {
  const database = databaseProcessEnvironment(required('DATABASE_URL'));
  const encryptionKey = parseBackupKey(
    required('BACKUP_ENCRYPTION_KEY_BASE64'),
  );
  const metricsPath = validateBackupMetricsPath(
    required('BACKUP_METRICS_FILE'),
  );
  const destinations = [
    destination('primary', 'BACKUP_PRIMARY'),
    destination('secondary', 'BACKUP_SECONDARY'),
  ];
  ensureIndependent(destinations);

  const directory = await mkdtemp(join(tmpdir(), 'sosedi-pg-backup-'));
  await chmod(directory, 0o700);
  const dumpPath = join(directory, 'database.dump');
  const encryptedPath = join(directory, 'database.dump.enc');
  const createdAt = new Date();
  const objectKey = `${BACKUP_PREFIX}${createdAt.toISOString().replaceAll(':', '-')}.dump.enc`;

  try {
    await runPgDump(database, dumpPath);
    await encryptBackupFile(dumpPath, encryptedPath, encryptionKey);
    const digest = await sha256File(encryptedPath);
    const encryptedSize = (await stat(encryptedPath)).size;

    for (const target of destinations) {
      await target.client.send(
        new PutObjectCommand({
          Bucket: target.bucket,
          Key: objectKey,
          Body: createReadStream(encryptedPath),
          ContentType: 'application/octet-stream',
          Metadata: {
            createdAt: createdAt.toISOString(),
            encryptedSha256: digest,
            format: 'pg-custom+a256gcm-v1',
          },
        }),
      );
    }

    for (const target of destinations) {
      const stored = await target.client.send(
        new HeadObjectCommand({
          Bucket: target.bucket,
          Key: objectKey,
        }),
      );
      assertStoredBackup(
        target.name,
        stored.ContentLength,
        stored.Metadata,
        encryptedSize,
        digest,
      );
    }

    for (const target of destinations) {
      await applyRetention(target, createdAt);
    }
    await publishBackupSuccessMetric(metricsPath, new Date());

    process.stdout.write(
      `PostgreSQL backup uploaded to primary and secondary: ${objectKey}\n`,
    );
  } finally {
    await rm(directory, { recursive: true, force: true });
    for (const target of destinations) {
      target.client.destroy();
    }
  }
}

export function assertStoredBackup(
  destinationName: string,
  storedSize: number | undefined,
  metadata: Readonly<Record<string, string>> | undefined,
  expectedSize: number,
  expectedDigest: string,
): void {
  const storedDigest = Object.entries(metadata ?? {}).find(
    ([key]) => key.toLowerCase() === 'encryptedsha256',
  )?.[1];
  if (storedSize !== expectedSize || storedDigest !== expectedDigest) {
    throw new Error(
      `${destinationName} backup verification failed: size or checksum metadata mismatch`,
    );
  }
}

export async function publishBackupSuccessMetric(
  path: string,
  completedAt: Date,
): Promise<void> {
  validateBackupMetricsPath(path);
  const timestamp = Math.floor(completedAt.getTime() / 1_000);
  if (!Number.isFinite(timestamp) || timestamp <= 0) {
    throw new Error('Backup completion timestamp is invalid');
  }
  const content =
    '# HELP sosedi_backup_last_success_timestamp_seconds Last verified encrypted dual-copy PostgreSQL backup.\n' +
    '# TYPE sosedi_backup_last_success_timestamp_seconds gauge\n' +
    `sosedi_backup_last_success_timestamp_seconds ${timestamp}\n`;
  const temporaryPath = join(
    dirname(path),
    `.sosedi_backup.${process.pid}.${randomUUID()}.tmp`,
  );
  try {
    await writeFile(temporaryPath, content, {
      encoding: 'utf8',
      flag: 'wx',
      mode: 0o644,
    });
    await rename(temporaryPath, path);
  } finally {
    await rm(temporaryPath, { force: true });
  }
}

function validateBackupMetricsPath(path: string): string {
  if (!isAbsolute(path) || basename(path) !== 'sosedi_backup.prom') {
    throw new Error(
      'BACKUP_METRICS_FILE must be an absolute sosedi_backup.prom path',
    );
  }
  return path;
}

function destination(
  name: BackupDestination['name'],
  prefix: string,
): BackupDestination {
  const endpoint = validateHttpsUrl(
    `${prefix}_S3_ENDPOINT`,
    required(`${prefix}_S3_ENDPOINT`),
  );
  const region = required(`${prefix}_S3_REGION`);
  const bucket = required(`${prefix}_S3_BUCKET`);
  const accessKeyId = required(`${prefix}_S3_ACCESS_KEY_ID`);
  const secretAccessKey = required(`${prefix}_S3_SECRET_ACCESS_KEY`);

  return {
    name,
    endpoint,
    bucket,
    client: new S3Client({
      endpoint,
      region,
      forcePathStyle: true,
      credentials: { accessKeyId, secretAccessKey },
    }),
  };
}

function ensureIndependent(destinations: BackupDestination[]): void {
  const [primary, secondary] = destinations;
  if (new URL(primary.endpoint).host === new URL(secondary.endpoint).host) {
    throw new Error(
      'Primary and secondary backup destinations must use different providers',
    );
  }
}

async function sha256File(path: string): Promise<string> {
  const hash = createHash('sha256');
  const stream = createReadStream(path);
  for await (const chunk of stream) {
    hash.update(chunk as Buffer);
  }
  return hash.digest('hex');
}

async function applyRetention(
  destinationConfig: BackupDestination,
  now: Date,
): Promise<void> {
  const cutoff = new Date(
    now.getTime() - RETENTION_DAYS * 24 * 60 * 60 * 1_000,
  );
  let continuationToken: string | undefined;

  do {
    const page = await destinationConfig.client.send(
      new ListObjectsV2Command({
        Bucket: destinationConfig.bucket,
        Prefix: BACKUP_PREFIX,
        ContinuationToken: continuationToken,
      }),
    );
    const expired = (page.Contents ?? [])
      .filter(
        (object) =>
          object.Key &&
          object.LastModified &&
          object.LastModified.getTime() < cutoff.getTime(),
      )
      .map((object) => ({ Key: object.Key! }));

    if (expired.length > 0) {
      await destinationConfig.client.send(
        new DeleteObjectsCommand({
          Bucket: destinationConfig.bucket,
          Delete: { Objects: expired, Quiet: true },
        }),
      );
    }
    continuationToken = page.NextContinuationToken;
  } while (continuationToken);
}

async function runPgDump(
  database: ReturnType<typeof databaseProcessEnvironment>,
  outputPath: string,
): Promise<void> {
  const binary = process.env.PG_DUMP_BIN ?? 'pg_dump';
  await new Promise<void>((resolve, reject) => {
    const child = spawn(
      binary,
      [
        '--format=custom',
        '--compress=6',
        '--no-owner',
        '--no-acl',
        '--file',
        outputPath,
        '--host',
        database.host,
        '--port',
        database.port,
        '--username',
        database.username,
        database.database,
      ],
      {
        env: {
          ...process.env,
          PGPASSWORD: database.password,
          PGSSLMODE: database.sslMode,
        },
        stdio: ['ignore', 'ignore', 'pipe'],
      },
    );
    let errorOutput = '';
    child.stderr.setEncoding('utf8');
    child.stderr.on('data', (chunk: string) => {
      errorOutput = `${errorOutput}${chunk}`.slice(-2_000);
    });
    child.on('error', reject);
    child.on('exit', (code) => {
      if (code === 0) {
        resolve();
        return;
      }
      reject(new Error(`pg_dump failed with code ${code}: ${errorOutput}`));
    });
  });
}

function databaseProcessEnvironment(databaseUrl: string): {
  host: string;
  port: string;
  username: string;
  password: string;
  database: string;
  sslMode: string;
} {
  const url = new URL(databaseUrl);
  if (url.protocol !== 'postgresql:' && url.protocol !== 'postgres:') {
    throw new Error('DATABASE_URL must use PostgreSQL');
  }
  return {
    host: url.hostname,
    port: url.port || '5432',
    username: decodeURIComponent(url.username),
    password: decodeURIComponent(url.password),
    database: decodeURIComponent(url.pathname.replace(/^\//, '')),
    sslMode: url.searchParams.get('sslmode') ?? 'require',
  };
}

function validateHttpsUrl(name: string, value: string): string {
  const url = new URL(value);
  if (url.protocol !== 'https:' || url.username || url.password) {
    throw new Error(`${name} must be an HTTPS URL without credentials`);
  }
  return url.toString();
}

function required(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`${name} is required`);
  }
  return value;
}

if (require.main === module) {
  void main().catch((error: unknown) => {
    const message = error instanceof Error ? error.message : 'Backup failed';
    process.stderr.write(`${message}\n`);
    process.exitCode = 1;
  });
}
