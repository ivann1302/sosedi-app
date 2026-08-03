export const REDACTED = '[REDACTED]';

const SENSITIVE_KEYS = new Set([
  'authorization',
  'proxyauthorization',
  'accesstoken',
  'refreshtoken',
  'admintoken',
  'token',
  'jwt',
  'cookie',
  'cookies',
  'setcookie',
  'xcsrftoken',
  'phone',
  'phonenumber',
  'mobile',
  'address',
  'pickupaddress',
  'dropoffaddress',
  'exactaddress',
  'coordinates',
  'exactcoordinates',
  'kyc',
  'kycdocument',
  'kycpayload',
  'passport',
  'passportnumber',
  'selfie',
  'paymentpayload',
  'paymentdata',
  'paymentdetails',
  'providerpayload',
  'cardnumber',
  'pan',
  'cvv',
  'cvc',
  'presignedurl',
  'uploadurl',
  'downloadurl',
  'secret',
  'clientsecret',
  'apikey',
  'otp',
  'otpcode',
  'verificationcode',
  'password',
]);

export function redactSensitiveData(value: unknown): unknown {
  return redactValue(value, new WeakSet<object>());
}

export function redactSensitiveText(value: string): string {
  return value
    .replace(
      /https?:\/\/[^\s,;]*(?:x-amz-|x-goog-|signature=)[^\s,;]*/gi,
      '[REDACTED_URL]',
    )
    .replace(/\bBearer\s+[A-Za-z0-9._~+/=-]+/gi, `Bearer ${REDACTED}`)
    .replace(/\beyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b/g, REDACTED)
    .replace(
      /\b(cookie|set-cookie)\s*:\s*[^,\r\n]*/gi,
      (_match, label: string) => `${label}: ${REDACTED}`,
    )
    .replace(
      /(?:\+7|8)[\s(-]*\d{3}[\s)-]*\d{3}[\s-]*\d{2}[\s-]*\d{2}\b/g,
      REDACTED,
    )
    .replace(
      /\b(otp|код)(\s*[:=]\s*|\s+)\d{4,8}\b/gi,
      (_match, label: string) => `${label}: ${REDACTED}`,
    );
}

function redactValue(value: unknown, seen: WeakSet<object>): unknown {
  if (typeof value === 'string') {
    return redactSensitiveText(value);
  }
  if (
    value === null ||
    value === undefined ||
    typeof value === 'number' ||
    typeof value === 'boolean' ||
    typeof value === 'bigint'
  ) {
    return value;
  }
  if (typeof value === 'symbol' || typeof value === 'function') {
    return String(value);
  }
  if (seen.has(value)) {
    return '[Circular]';
  }
  seen.add(value);

  if (value instanceof Error) {
    return {
      name: value.name,
      message: redactSensitiveText(value.message),
      stack: value.stack ? redactSensitiveText(value.stack) : undefined,
    };
  }
  if (value instanceof Date) {
    return value.toISOString();
  }
  if (Array.isArray(value)) {
    return value.map((entry) => redactValue(entry, seen));
  }
  if (value instanceof Map) {
    return Object.fromEntries(
      [...value.entries()].map(([key, entry]) => [
        String(key),
        isSensitiveKey(String(key)) ? REDACTED : redactValue(entry, seen),
      ]),
    );
  }
  if (value instanceof Set) {
    return [...value].map((entry) => redactValue(entry, seen));
  }

  return Object.fromEntries(
    Object.entries(value).map(([key, entry]) => [
      key,
      isSensitiveKey(key) ? REDACTED : redactValue(entry, seen),
    ]),
  );
}

function isSensitiveKey(key: string): boolean {
  const normalized = key.toLowerCase().replace(/[^a-z0-9]/g, '');
  return (
    SENSITIVE_KEYS.has(normalized) ||
    normalized.endsWith('token') ||
    normalized.endsWith('secret')
  );
}
