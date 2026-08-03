import { createCipheriv, createDecipheriv, randomBytes } from 'node:crypto';
import { appendFile, open, stat, writeFile } from 'node:fs/promises';
import { createReadStream, createWriteStream } from 'node:fs';
import { pipeline } from 'node:stream/promises';

const MAGIC = Buffer.from('SOSPG001');
const IV_BYTES = 12;
const TAG_BYTES = 16;
const HEADER_BYTES = MAGIC.length + IV_BYTES;

export function parseBackupKey(rawKey: string): Buffer {
  const key = Buffer.from(rawKey, 'base64');
  if (key.length !== 32 || key.toString('base64') !== rawKey) {
    throw new Error('BACKUP_ENCRYPTION_KEY_BASE64 must contain 32 bytes');
  }
  return key;
}

export async function encryptBackupFile(
  inputPath: string,
  outputPath: string,
  key: Buffer,
): Promise<void> {
  if (key.length !== 32) {
    throw new Error('Backup encryption requires a 32-byte key');
  }

  const iv = randomBytes(IV_BYTES);
  await writeFile(outputPath, Buffer.concat([MAGIC, iv]), {
    flag: 'wx',
    mode: 0o600,
  });

  const cipher = createCipheriv('aes-256-gcm', key, iv);
  await pipeline(
    createReadStream(inputPath),
    cipher,
    createWriteStream(outputPath, { flags: 'a', mode: 0o600 }),
  );
  await appendFile(outputPath, cipher.getAuthTag());
}

export async function decryptBackupFile(
  inputPath: string,
  outputPath: string,
  key: Buffer,
): Promise<void> {
  if (key.length !== 32) {
    throw new Error('Backup decryption requires a 32-byte key');
  }

  const inputStat = await stat(inputPath);
  if (inputStat.size <= HEADER_BYTES + TAG_BYTES) {
    throw new Error('Encrypted backup is truncated');
  }

  const handle = await open(inputPath, 'r');
  const header = Buffer.alloc(HEADER_BYTES);
  const tag = Buffer.alloc(TAG_BYTES);
  try {
    await handle.read(header, 0, header.length, 0);
    await handle.read(tag, 0, tag.length, inputStat.size - TAG_BYTES);
  } finally {
    await handle.close();
  }

  if (!header.subarray(0, MAGIC.length).equals(MAGIC)) {
    throw new Error('Encrypted backup format is unsupported');
  }

  const iv = header.subarray(MAGIC.length);
  const decipher = createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(tag);
  await pipeline(
    createReadStream(inputPath, {
      start: HEADER_BYTES,
      end: inputStat.size - TAG_BYTES - 1,
    }),
    decipher,
    createWriteStream(outputPath, { flags: 'wx', mode: 0o600 }),
  );
}
