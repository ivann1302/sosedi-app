import {
  BadRequestException,
  ConflictException,
  Injectable,
} from '@nestjs/common';
import { createHash } from 'node:crypto';

export type FakePaymentRequest = {
  idempotencyKey: string;
  bookingId: string;
  amountMinor: bigint;
  currency: 'RUB';
};

export type FakePayment = FakePaymentRequest & {
  providerPaymentId: string;
  checkoutUrl: string;
  status: 'PENDING';
};

@Injectable()
export class FakePaymentProvider {
  private readonly payments = new Map<string, FakePayment>();

  createPayment(request: FakePaymentRequest): FakePayment {
    this.validateRequest(request);

    const existing = this.payments.get(request.idempotencyKey);
    if (existing) {
      if (!this.matches(existing, request)) {
        throw new ConflictException(
          'Idempotency key already belongs to another payment',
        );
      }
      return existing;
    }

    const providerPaymentId = `fake_${createHash('sha256')
      .update(request.idempotencyKey)
      .digest('hex')
      .slice(0, 24)}`;
    const payment: FakePayment = {
      ...request,
      providerPaymentId,
      checkoutUrl: `https://payments.invalid/${providerPaymentId}`,
      status: 'PENDING',
    };
    this.payments.set(request.idempotencyKey, payment);
    return payment;
  }

  private validateRequest(request: FakePaymentRequest): void {
    if (!request.idempotencyKey.trim() || !request.bookingId.trim()) {
      throw new BadRequestException(
        'Idempotency key and booking ID are required',
      );
    }
    if (request.currency !== 'RUB' || request.amountMinor <= 0n) {
      throw new BadRequestException(
        'Fake payment requires a positive RUB amount in minor units',
      );
    }
  }

  private matches(existing: FakePayment, request: FakePaymentRequest): boolean {
    return (
      existing.bookingId === request.bookingId &&
      existing.amountMinor === request.amountMinor &&
      existing.currency === request.currency
    );
  }
}
