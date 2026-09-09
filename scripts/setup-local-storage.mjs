import { randomBytes } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync, chmodSync } from 'node:fs';
import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const require = createRequire(new URL('../backend/package.json', import.meta.url));
const { parse } = require('dotenv');
const { S3Client, CreateBucketCommand, PutBucketPolicyCommand } = require('@aws-sdk/client-s3');
const path = `${root}backend/.env.storage.local`;
if (process.env.NODE_ENV === 'production') throw new Error('Local storage is development-only');
if (!existsSync(path)) {
  writeFileSync(path, [
    'NODE_ENV=development', 'SMS_PROVIDER=console', 'DEV_SMS_OTP_CODE=123456',
    'S3_ENDPOINT=http://127.0.0.1:9030', 'S3_REGION=us-east-1',
    'S3_BUCKET_PUBLIC=sosedi-local-public', 'S3_BUCKET_PRIVATE=sosedi-local-private',
    'S3_PUBLIC_BASE_URL=http://127.0.0.1:9030/sosedi-local-public',
    'S3_FORCE_PATH_STYLE=true', `ADMIN_MFA_ENCRYPTION_KEY=${randomBytes(32).toString('base64')}`, `S3_ACCESS_KEY=${randomBytes(12).toString('hex')}`,
    `S3_SECRET_KEY=${randomBytes(24).toString('hex')}`, '',
  ].join('\n'), { mode: 0o600, flag: 'wx' });
}
chmodSync(path, 0o600);
const config = parse(readFileSync(path));
if (config.NODE_ENV !== 'development' || config.S3_ENDPOINT !== 'http://127.0.0.1:9030' ||
    config.S3_BUCKET_PUBLIC !== 'sosedi-local-public' || config.S3_BUCKET_PRIVATE !== 'sosedi-local-private') {
  throw new Error('Refusing non-local storage configuration');
}
const compose = spawnSync('docker', ['compose', '-p', 'sosedi-local-storage', '--env-file', path,
  '-f', 'docker-compose.storage.yml', 'up', '-d', '--wait', '--wait-timeout', '90'],
{ cwd: root, stdio: 'inherit' });
if (compose.status !== 0) process.exit(compose.status ?? 1);
const client = new S3Client({ endpoint: config.S3_ENDPOINT, region: config.S3_REGION,
  forcePathStyle: true, credentials: { accessKeyId: config.S3_ACCESS_KEY, secretAccessKey: config.S3_SECRET_KEY } });
try {
  for (const Bucket of [config.S3_BUCKET_PUBLIC, config.S3_BUCKET_PRIVATE]) {
    try { await client.send(new CreateBucketCommand({ Bucket })); }
    catch (error) { if (error.name !== 'BucketAlreadyOwnedByYou') throw error; }
  }
  await client.send(new PutBucketPolicyCommand({ Bucket: config.S3_BUCKET_PUBLIC,
    Policy: JSON.stringify({ Version: '2012-10-17', Statement: [{ Effect: 'Allow',
      Principal: '*', Action: ['s3:GetObject'], Resource: [`arn:aws:s3:::${config.S3_BUCKET_PUBLIC}/items/*`] }] }) }));
  console.log('Local storage ready on 127.0.0.1:9030; private bucket requires signed access.');
} finally { client.destroy(); }
