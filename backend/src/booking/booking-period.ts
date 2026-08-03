import { BadRequestException } from '@nestjs/common';

export const BOOKING_MAX_DAYS = 30;
export const BOOKING_HORIZON_DAYS = 90;

export type BookingPeriod = {
  startDate: Date;
  endDate: Date;
  days: number;
};

export function parseBookingPeriod(
  start: string,
  end: string,
  today = moscowCalendarDate(),
): BookingPeriod {
  const startDate = parseCalendarDate(start);
  const endDate = parseCalendarDate(end);
  const todayDate = parseCalendarDate(today);

  if (startDate < todayDate) {
    throw new BadRequestException('Дата начала не может быть в прошлом');
  }
  if (endDate < startDate) {
    throw new BadRequestException('Дата окончания раньше даты начала');
  }

  const days = differenceInDays(startDate, endDate) + 1;
  if (days > BOOKING_MAX_DAYS) {
    throw new BadRequestException(
      `Максимальный срок аренды — ${BOOKING_MAX_DAYS} дней`,
    );
  }
  if (differenceInDays(todayDate, startDate) > BOOKING_HORIZON_DAYS) {
    throw new BadRequestException(
      `Бронирование доступно не более чем за ${BOOKING_HORIZON_DAYS} дней`,
    );
  }

  return { startDate, endDate, days };
}

export function moscowCalendarDate(now = new Date()): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Europe/Moscow',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(now);
}

function parseCalendarDate(value: string): Date {
  const date = new Date(`${value}T00:00:00.000Z`);
  if (
    Number.isNaN(date.getTime()) ||
    date.toISOString().slice(0, 10) !== value
  ) {
    throw new BadRequestException('Некорректная календарная дата');
  }
  return date;
}

function differenceInDays(from: Date, to: Date): number {
  return Math.floor((to.getTime() - from.getTime()) / 86_400_000);
}
