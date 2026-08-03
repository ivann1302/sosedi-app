import {
  REDACTED,
  redactSensitiveData,
  redactSensitiveText,
} from './sensitive-data-redactor';

describe('sensitive data redaction', () => {
  it('recursively removes sensitive values while preserving safe context', () => {
    const input = {
      eventId: 'event-123',
      errorCode: 'BOOKING_CONFLICT',
      headers: {
        authorization: 'Bearer access-secret',
        cookie: 'session=cookie-secret',
        'x-csrf-token': 'csrf-secret',
      },
      auth: {
        refreshToken: 'refresh-secret',
        otpCode: '123456',
        phone: '+79991234567',
      },
      item: {
        id: 'item-1',
        pickupAddress: 'Москва, Тверская, 1',
      },
      kycDocument: { passport: '4510 123456' },
      paymentPayload: { cardNumber: '4111111111111111' },
      presignedUrl:
        'https://storage.example/item.jpg?X-Amz-Signature=signed-secret',
    };

    expect(redactSensitiveData(input)).toEqual({
      eventId: 'event-123',
      errorCode: 'BOOKING_CONFLICT',
      headers: {
        authorization: REDACTED,
        cookie: REDACTED,
        'x-csrf-token': REDACTED,
      },
      auth: {
        refreshToken: REDACTED,
        otpCode: REDACTED,
        phone: REDACTED,
      },
      item: {
        id: 'item-1',
        pickupAddress: REDACTED,
      },
      kycDocument: REDACTED,
      paymentPayload: REDACTED,
      presignedUrl: REDACTED,
    });
  });

  it('redacts secrets embedded in otherwise unstructured messages', () => {
    const message = [
      'authorization=Bearer eyJhbGciOiJIUzI1NiJ9.payload.signature',
      'phone +7 (999) 123-45-67',
      'OTP: 123456',
      'Cookie: session=cookie-secret',
      'upload https://storage.example/item.jpg?X-Amz-Signature=url-secret',
    ].join('; ');

    const redacted = redactSensitiveText(message);

    expect(redacted).toContain('authorization=');
    expect(redacted).toContain('phone');
    expect(redacted).not.toContain('eyJhbGciOiJIUzI1NiJ9');
    expect(redacted).not.toContain('999) 123-45-67');
    expect(redacted).not.toContain('123456');
    expect(redacted).not.toContain('cookie-secret');
    expect(redacted).not.toContain('storage.example');
    expect(redacted).not.toContain('url-secret');
  });

  it('sanitizes errors and cyclic structures without throwing', () => {
    const error = new Error(
      'OTP: 654321 for +79991234567 with Bearer access-secret',
    );
    const cyclic: Record<string, unknown> = { error };
    cyclic.self = cyclic;

    const redacted = redactSensitiveData(cyclic);
    const serialized = JSON.stringify(redacted);

    expect(serialized).toContain('"name":"Error"');
    expect(serialized).toContain('[Circular]');
    expect(serialized).not.toContain('654321');
    expect(serialized).not.toContain('79991234567');
    expect(serialized).not.toContain('access-secret');
  });
});
