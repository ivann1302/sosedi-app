import { spawn } from 'node:child_process';
import { chmod, mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { LATEST_REQUIRED_MIGRATION } from '../app.service';
import { decryptBackupFile, parseBackupKey } from './postgres-backup-crypto';

type DatabaseTarget = {
  host: string;
  port: string;
  username: string;
  password: string;
  database: string;
  sslMode: string;
};

async function main(): Promise<void> {
  const backupPath = resolve(required('RESTORE_BACKUP_FILE'));
  const target = parseTarget(required('RESTORE_DATABASE_URL'));
  assertIsolatedTarget(target, required('RESTORE_CONFIRM_TARGET'));
  const key = parseBackupKey(required('BACKUP_ENCRYPTION_KEY_BASE64'));
  const directory = await mkdtemp(join(tmpdir(), 'sosedi-pg-restore-'));
  await chmod(directory, 0o700);
  const dumpPath = join(directory, 'database.dump');

  try {
    await decryptBackupFile(backupPath, dumpPath, key);
    await run(
      process.env.PG_RESTORE_BIN ?? 'pg_restore',
      ['--list', dumpPath],
      target,
    );
    const existingTable = await run(
      process.env.PSQL_BIN ?? 'psql',
      [
        '--host',
        target.host,
        '--port',
        target.port,
        '--username',
        target.username,
        '--dbname',
        target.database,
        '--tuples-only',
        '--no-align',
        '--command',
        `SELECT quote_ident(schemaname) || '.' || quote_ident(tablename)
         FROM pg_tables
         WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
           AND NOT (schemaname = 'public' AND tablename = 'spatial_ref_sys')
         ORDER BY schemaname, tablename
         LIMIT 1`,
      ],
      target,
    );
    assertRestoreTargetIsEmpty(existingTable);
    await run(
      process.env.PG_RESTORE_BIN ?? 'pg_restore',
      [
        '--exit-on-error',
        '--no-owner',
        '--no-acl',
        '--host',
        target.host,
        '--port',
        target.port,
        '--username',
        target.username,
        '--dbname',
        target.database,
        dumpPath,
      ],
      target,
    );
    const migration = await run(
      process.env.PSQL_BIN ?? 'psql',
      [
        '--host',
        target.host,
        '--port',
        target.port,
        '--username',
        target.username,
        '--dbname',
        target.database,
        '--tuples-only',
        '--no-align',
        '--command',
        'SELECT migration_name FROM "_prisma_migrations" WHERE finished_at IS NOT NULL AND rolled_back_at IS NULL ORDER BY finished_at DESC LIMIT 1',
      ],
      target,
    );
    if (migration.trim() !== LATEST_REQUIRED_MIGRATION) {
      throw new Error(
        'Restored database does not contain the required migration',
      );
    }
    process.stdout.write(
      `PostgreSQL restore drill completed for ${target.database}\n`,
    );
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

export function assertRestoreTargetIsEmpty(existingTable: string): void {
  const table = existingTable.trim();
  if (table) {
    throw new Error(
      `Restore target must be empty; found application table ${table}`,
    );
  }
}

export function assertIsolatedTarget(
  target: DatabaseTarget,
  confirmation: string,
): void {
  const targetId = `${target.host}:${target.port}/${target.database}`;
  if (target.database.startsWith('sosedi_restore_') !== true) {
    throw new Error('Restore database must start with sosedi_restore_');
  }
  if (confirmation !== targetId) {
    throw new Error(`RESTORE_CONFIRM_TARGET must equal ${targetId}`);
  }
}

function parseTarget(databaseUrl: string): DatabaseTarget {
  const url = new URL(databaseUrl);
  if (url.protocol !== 'postgresql:' && url.protocol !== 'postgres:') {
    throw new Error('RESTORE_DATABASE_URL must use PostgreSQL');
  }
  const database = decodeURIComponent(url.pathname.replace(/^\//, ''));
  if (!url.hostname || !url.username || !database) {
    throw new Error('RESTORE_DATABASE_URL is incomplete');
  }
  return {
    host: url.hostname,
    port: url.port || '5432',
    username: decodeURIComponent(url.username),
    password: decodeURIComponent(url.password),
    database,
    sslMode: url.searchParams.get('sslmode') ?? 'require',
  };
}

function run(
  binary: string,
  args: string[],
  target: DatabaseTarget,
): Promise<string> {
  return new Promise((resolveRun, reject) => {
    const child = spawn(binary, args, {
      env: {
        ...process.env,
        PGPASSWORD: target.password,
        PGSSLMODE: target.sslMode,
      },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let output = '';
    let errorOutput = '';
    child.stdout.setEncoding('utf8');
    child.stderr.setEncoding('utf8');
    child.stdout.on('data', (chunk: string) => {
      output = `${output}${chunk}`.slice(-8_000);
    });
    child.stderr.on('data', (chunk: string) => {
      errorOutput = `${errorOutput}${chunk}`.slice(-2_000);
    });
    child.on('error', reject);
    child.on('exit', (code) => {
      if (code === 0) {
        resolveRun(output);
        return;
      }
      reject(new Error(`${binary} failed with code ${code}: ${errorOutput}`));
    });
  });
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
    const message = error instanceof Error ? error.message : 'Restore failed';
    process.stderr.write(`${message}\n`);
    process.exitCode = 1;
  });
}
