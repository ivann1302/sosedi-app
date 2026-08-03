import { BadRequestException } from '@nestjs/common';
import { parseBookingPeriod } from './booking-period';

describe('parseBookingPeriod', () => {
  it('uses inclusive Moscow calendar dates and allows one day', () => {
    expect(
      parseBookingPeriod('2026-08-01', '2026-08-01', '2026-07-29'),
    ).toEqual({
      startDate: new Date('2026-08-01T00:00:00.000Z'),
      endDate: new Date('2026-08-01T00:00:00.000Z'),
      days: 1,
    });
  });

  it.each([
    ['past', '2026-07-28', '2026-07-29'],
    ['reversed', '2026-08-02', '2026-08-01'],
    ['over 30 days', '2026-08-01', '2026-08-31'],
    ['over horizon', '2026-10-28', '2026-10-28'],
  ])('rejects %s periods', (_, start, end) => {
    expect(() => parseBookingPeriod(start, end, '2026-07-29')).toThrow(
      BadRequestException,
    );
  });
});
