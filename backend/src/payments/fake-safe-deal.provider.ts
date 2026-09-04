import {
  BadRequestException,
  ConflictException,
  Injectable,
} from '@nestjs/common';
import { DepositOperationKind } from '@prisma/client';
import { createHash } from 'node:crypto';

export type FakeOperationOutcome = 'SUCCESS' | 'DECLINE' | 'TIMEOUT';

export type FakeCheckoutRequest = {
  idempotencyKey: string;
  bookingId: string;
  amountMinor: bigint;
  currency: 'RUB';
  outcome: FakeOperationOutcome;
};

export type FakeDepositOperationRequest = {
  idempotencyKey: string;
  depositId: string;
  kind: DepositOperationKind;
  amountMinor: bigint;
  currency: 'RUB';
  outcome: FakeOperationOutcome;
};

export type ProviderOperationResult =
  | { outcome: 'SUCCEEDED'; providerOperationId: string }
  | { outcome: 'DECLINED'; errorCode: string }
  | { outcome: 'TIMEOUT' };

type StoredOperation = {
  fingerprint: string;
  result: ProviderOperationResult;
};

@Injectable()
export class FakeSafeDealProvider {
  private readonly operations = new Map<string, StoredOperation>();

  checkout(request: FakeCheckoutRequest): Promise<ProviderOperationResult> {
    return Promise.resolve().then(() =>
      this.execute('checkout', request.idempotencyKey, request),
    );
  }

  executeDepositOperation(
    request: FakeDepositOperationRequest,
  ): Promise<ProviderOperationResult> {
    return Promise.resolve().then(() =>
      this.execute('deposit', request.idempotencyKey, request),
    );
  }

  private execute(
    command: 'checkout' | 'deposit',
    idempotencyKey: string,
    request: FakeCheckoutRequest | FakeDepositOperationRequest,
  ): ProviderOperationResult {
    this.validate(request);
    const fingerprint = JSON.stringify(request, (_key, value: unknown) =>
      typeof value === 'bigint' ? value.toString() : value,
    );
    const existing = this.operations.get(idempotencyKey);
    if (existing) {
      if (existing.fingerprint !== fingerprint) {
        throw new ConflictException(
          'Idempotency key already belongs to another fake operation',
        );
      }
      return existing.result;
    }

    const result = this.result(command, idempotencyKey, request.outcome);
    this.operations.set(idempotencyKey, { fingerprint, result });
    return result;
  }

  private validate(
    request: FakeCheckoutRequest | FakeDepositOperationRequest,
  ): void {
    const targetId =
      'bookingId' in request ? request.bookingId : request.depositId;
    if (!request.idempotencyKey.trim() || !targetId.trim()) {
      throw new BadRequestException(
        'Idempotency key and operation target are required',
      );
    }
    if (request.currency !== 'RUB' || request.amountMinor <= 0n) {
      throw new BadRequestException(
        'Fake operation requires a positive RUB amount in minor units',
      );
    }
  }

  private result(
    command: 'checkout' | 'deposit',
    idempotencyKey: string,
    outcome: FakeOperationOutcome,
  ): ProviderOperationResult {
    if (outcome === 'DECLINE') {
      return { outcome: 'DECLINED', errorCode: 'FAKE_DECLINED' };
    }
    if (outcome === 'TIMEOUT') {
      return { outcome: 'TIMEOUT' };
    }
    return {
      outcome: 'SUCCEEDED',
      providerOperationId: `fake_${command}_${createHash('sha256')
        .update(`${command}:${idempotencyKey}`)
        .digest('hex')
        .slice(0, 24)}`,
    };
  }
}
