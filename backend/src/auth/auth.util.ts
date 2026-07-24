import { BadRequestException } from '@nestjs/common';

export function normalizeRussianPhone(phone: string): string {
  const digits = phone.replace(/\D/g, '');

  if (digits.length === 10 && digits.startsWith('9')) {
    return `+7${digits}`;
  }

  if (digits.length === 11 && digits.startsWith('8')) {
    return `+7${digits.slice(1)}`;
  }

  if (digits.length === 11 && digits.startsWith('7')) {
    return `+${digits}`;
  }

  throw new BadRequestException('Некорректный номер телефона');
}

export function parseDurationToSeconds(value: string): number {
  const match = /^(\d+)([smhd])?$/.exec(value.trim());
  if (!match) {
    throw new Error(`Invalid duration: ${value}`);
  }

  const amount = Number(match[1]);
  const unit = match[2] ?? 's';
  const multipliers: Record<string, number> = {
    s: 1,
    m: 60,
    h: 60 * 60,
    d: 24 * 60 * 60,
  };

  return amount * multipliers[unit];
}
