import { AdminCapability } from '@prisma/client';
import { parseBootstrapCapabilities } from './first-admin-bootstrap';

describe('parseBootstrapCapabilities', () => {
  it('accepts financial capabilities while preserving deduplication', () => {
    expect(
      parseBootstrapCapabilities('DISPUTE,FINANCE,DISPUTE,SUPPORT'),
    ).toEqual([
      AdminCapability.DISPUTE,
      AdminCapability.FINANCE,
      AdminCapability.SUPPORT,
    ]);
  });

  it('still rejects unknown capabilities', () => {
    expect(() => parseBootstrapCapabilities('DISPUTE,ROOT')).toThrow();
  });
});
