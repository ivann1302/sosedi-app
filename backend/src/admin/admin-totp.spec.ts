import { generateTotpCode, verifyTotpCode } from './admin-totp';

describe('admin TOTP', () => {
  const rfcSecret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

  it('matches the 6-digit form of the RFC 6238 SHA-1 vector', () => {
    expect(generateTotpCode(rfcSecret, 59)).toBe('287082');
    expect(verifyTotpCode(rfcSecret, '287082', undefined, 59)).toEqual({
      valid: true,
      timeStep: 1,
    });
  });

  it('rejects a previously consumed time step', () => {
    expect(verifyTotpCode(rfcSecret, '287082', 1, 59)).toEqual({
      valid: false,
    });
  });

  it('tolerates one clock step but rejects a two-step drift', () => {
    const token = generateTotpCode(rfcSecret, 60);

    expect(verifyTotpCode(rfcSecret, token, undefined, 90)).toEqual({
      valid: true,
      timeStep: 2,
    });
    expect(verifyTotpCode(rfcSecret, token, undefined, 120)).toEqual({
      valid: false,
    });
  });
});
