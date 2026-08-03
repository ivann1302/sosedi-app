import {
  GetObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { createHash } from 'node:crypto';

const MAX_SAMPLE_BYTES = 20 * 1024 * 1024;
const ISOLATED_PREFIX_PATTERN =
  /^sosedi-restore-sample\/[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/;

export type S3RestoreSampleInput = {
  sourceBucket: string;
  sourceKey: string;
  sourceVersionId?: string;
  expectedSha256: string;
  targetBucket: string;
  targetPrefix: string;
  targetConfirmation: string;
};

export type S3RestoreSampleResult = {
  sha256: string;
  sizeBytes: number;
  sourceKeySha256: string;
  targetKey: string;
};

export async function restoreS3Sample(
  input: S3RestoreSampleInput,
  sourceClient: S3Client,
  targetClient: S3Client,
): Promise<S3RestoreSampleResult> {
  validateInput(input);

  const source = await sourceClient.send(
    new GetObjectCommand({
      Bucket: input.sourceBucket,
      Key: input.sourceKey,
      VersionId: input.sourceVersionId,
    }),
  );
  const sourceBytes = await boundedBody(
    source.Body,
    source.ContentLength,
    'Source object',
  );
  const sourceSha256 = sha256(sourceBytes);
  if (sourceSha256 !== input.expectedSha256) {
    throw new Error('Source object checksum mismatch');
  }

  const sourceKeySha256 = sha256(Buffer.from(input.sourceKey));
  const targetKey = `${input.targetPrefix}/${sourceSha256.slice(0, 16)}.sample`;
  await targetClient.send(
    new PutObjectCommand({
      Bucket: input.targetBucket,
      Key: targetKey,
      Body: sourceBytes,
      ContentType: safeContentType(source.ContentType),
      ServerSideEncryption: 'AES256',
      Metadata: {
        restoredsha256: sourceSha256,
        sourcekeysha256: sourceKeySha256,
      },
    }),
  );

  const restored = await targetClient.send(
    new GetObjectCommand({
      Bucket: input.targetBucket,
      Key: targetKey,
    }),
  );
  const restoredBytes = await boundedBody(
    restored.Body,
    restored.ContentLength,
    'Restored object',
  );
  if (sha256(restoredBytes) !== sourceSha256) {
    throw new Error('Restored object checksum mismatch');
  }

  return {
    sha256: sourceSha256,
    sizeBytes: sourceBytes.length,
    sourceKeySha256,
    targetKey,
  };
}

function validateInput(input: S3RestoreSampleInput): void {
  const confirmedTarget = `${input.targetBucket}/${input.targetPrefix}`;
  if (
    !validBucket(input.sourceBucket) ||
    !input.sourceKey ||
    !validBucket(input.targetBucket) ||
    !ISOLATED_PREFIX_PATTERN.test(input.targetPrefix) ||
    input.targetConfirmation !== confirmedTarget
  ) {
    throw new Error(
      'An explicitly confirmed isolated restore target is required',
    );
  }
  if (input.targetBucket === input.sourceBucket) {
    throw new Error(
      'Restore target bucket must be distinct from the source bucket',
    );
  }
  if (!/^[a-f0-9]{64}$/.test(input.expectedSha256)) {
    throw new Error('Expected SHA-256 must be 64 lowercase hex characters');
  }
}

async function boundedBody(
  body: { transformToByteArray(): Promise<Uint8Array> } | undefined,
  declaredLength: number | undefined,
  label: string,
): Promise<Buffer> {
  if (!body) {
    throw new Error(`${label} has no body`);
  }
  if (
    declaredLength === undefined ||
    declaredLength <= 0 ||
    declaredLength > MAX_SAMPLE_BYTES
  ) {
    throw new Error(`${label} must have a bounded ContentLength`);
  }
  const bytes = Buffer.from(await body.transformToByteArray());
  if (bytes.length !== declaredLength) {
    throw new Error(`${label} size does not match ContentLength`);
  }
  return bytes;
}

function safeContentType(value: string | undefined): string {
  return value && /^[A-Za-z0-9.+-]+\/[A-Za-z0-9.+-]+$/.test(value)
    ? value
    : 'application/octet-stream';
}

function validBucket(value: string): boolean {
  return /^[A-Za-z0-9][A-Za-z0-9.-]{1,61}[A-Za-z0-9]$/.test(value);
}

function sha256(value: Buffer): string {
  return createHash('sha256').update(value).digest('hex');
}

function required(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`${name} is required`);
  }
  return value;
}

function optional(name: string): string | undefined {
  return process.env[name]?.trim() || undefined;
}

export function requireDistinctRestoreIdentities(
  sourceAccessKeyId: string,
  targetAccessKeyId: string,
): void {
  if (sourceAccessKeyId === targetAccessKeyId) {
    throw new Error('S3 restore must use distinct scoped identities');
  }
}

function client(prefix: 'SOURCE' | 'TARGET', accessKeyId: string): S3Client {
  const endpoint = required(`S3_RESTORE_${prefix}_ENDPOINT`);
  const url = new URL(endpoint);
  if (url.protocol !== 'https:' || url.username || url.password) {
    throw new Error(
      `S3_RESTORE_${prefix}_ENDPOINT must be HTTPS without credentials`,
    );
  }
  return new S3Client({
    endpoint: url.toString(),
    region: required(`S3_RESTORE_${prefix}_REGION`),
    forcePathStyle: true,
    credentials: {
      accessKeyId,
      secretAccessKey: required(`S3_RESTORE_${prefix}_SECRET_ACCESS_KEY`),
    },
  });
}

async function main(): Promise<void> {
  const sourceAccessKeyId = required('S3_RESTORE_SOURCE_ACCESS_KEY_ID');
  const targetAccessKeyId = required('S3_RESTORE_TARGET_ACCESS_KEY_ID');
  requireDistinctRestoreIdentities(sourceAccessKeyId, targetAccessKeyId);
  const sourceClient = client('SOURCE', sourceAccessKeyId);
  const targetClient = client('TARGET', targetAccessKeyId);
  try {
    const result = await restoreS3Sample(
      {
        sourceBucket: required('S3_RESTORE_SOURCE_BUCKET'),
        sourceKey: required('S3_RESTORE_SOURCE_KEY'),
        sourceVersionId: optional('S3_RESTORE_SOURCE_VERSION_ID'),
        expectedSha256: required('S3_RESTORE_EXPECTED_SHA256'),
        targetBucket: required('S3_RESTORE_TARGET_BUCKET'),
        targetPrefix: required('S3_RESTORE_TARGET_PREFIX'),
        targetConfirmation: required('S3_RESTORE_CONFIRM_TARGET'),
      },
      sourceClient,
      targetClient,
    );
    process.stdout.write(
      `S3 restore sample verified: ${JSON.stringify(result)}\n`,
    );
  } finally {
    sourceClient.destroy();
    targetClient.destroy();
  }
}

if (require.main === module) {
  void main().catch((error: unknown) => {
    const message =
      error instanceof Error ? error.message : 'S3 restore sample failed';
    process.stderr.write(`${message}\n`);
    process.exitCode = 1;
  });
}
