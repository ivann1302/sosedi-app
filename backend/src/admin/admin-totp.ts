import { createHmac, randomBytes, timingSafeEqual } from 'node:crypto';

const BASE32_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
const TOTP_PERIOD_SECONDS = 30;

export function generateTotpSecret(): string {
  return encodeBase32(randomBytes(20));
}

export function buildTotpUri(
  issuer: string,
  label: string,
  secret: string,
): string {
  const account = `${encodeURIComponent(issuer)}:${encodeURIComponent(label)}`;
  const query = new URLSearchParams({
    secret,
    issuer,
    algorithm: 'SHA1',
    digits: '6',
    period: String(TOTP_PERIOD_SECONDS),
  });
  return `otpauth://totp/${account}?${query.toString()}`;
}

export function verifyTotpCode(
  secret: string,
  token: string,
  afterTimeStep?: number,
  epochSeconds = Math.floor(Date.now() / 1000),
): { valid: false } | { valid: true; timeStep: number } {
  if (!/^\d{6}$/.test(token)) {
    return { valid: false };
  }

  const currentTimeStep = Math.floor(epochSeconds / TOTP_PERIOD_SECONDS);
  for (const offset of [-1, 0, 1]) {
    const timeStep = currentTimeStep + offset;
    if (
      timeStep < 0 ||
      (afterTimeStep !== undefined && timeStep <= afterTimeStep)
    ) {
      continue;
    }
    const expected = generateTotpCode(secret, timeStep * TOTP_PERIOD_SECONDS);
    if (timingSafeEqual(Buffer.from(expected), Buffer.from(token))) {
      return { valid: true, timeStep };
    }
  }
  return { valid: false };
}

export function generateTotpCode(
  secret: string,
  epochSeconds = Math.floor(Date.now() / 1000),
): string {
  const timeStep = Math.floor(epochSeconds / TOTP_PERIOD_SECONDS);
  const counter = Buffer.alloc(8);
  counter.writeBigUInt64BE(BigInt(timeStep));
  const digest = createHmac('sha1', decodeBase32(secret))
    .update(counter)
    .digest();
  const offset = digest[digest.length - 1] & 0x0f;
  const value =
    (((digest[offset] & 0x7f) << 24) |
      (digest[offset + 1] << 16) |
      (digest[offset + 2] << 8) |
      digest[offset + 3]) %
    1_000_000;
  return value.toString().padStart(6, '0');
}

function encodeBase32(value: Uint8Array): string {
  let bits = 0;
  let accumulator = 0;
  let encoded = '';

  for (const byte of value) {
    accumulator = (accumulator << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      encoded += BASE32_ALPHABET[(accumulator >>> bits) & 31];
    }
  }
  if (bits > 0) {
    encoded += BASE32_ALPHABET[(accumulator << (5 - bits)) & 31];
  }
  return encoded;
}

function decodeBase32(value: string): Buffer {
  const normalized = value.toUpperCase().replace(/=+$/g, '');
  let bits = 0;
  let accumulator = 0;
  const decoded: number[] = [];

  for (const character of normalized) {
    const index = BASE32_ALPHABET.indexOf(character);
    if (index < 0) {
      throw new Error('Invalid Base32 TOTP secret');
    }
    accumulator = (accumulator << 5) | index;
    bits += 5;
    if (bits >= 8) {
      bits -= 8;
      decoded.push((accumulator >>> bits) & 0xff);
    }
  }
  return Buffer.from(decoded);
}
