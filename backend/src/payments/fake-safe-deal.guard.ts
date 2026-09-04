import {
  BadRequestException,
  type CanActivate,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PaymentPolicyService } from './payment-policy.service';

@Injectable()
export class FakeSafeDealGuard implements CanActivate {
  constructor(private readonly paymentPolicy: PaymentPolicyService) {}

  canActivate(): boolean {
    try {
      this.paymentPolicy.requireFakeSafeDeal();
      return true;
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw new NotFoundException('Ресурс не найден');
      }
      throw error;
    }
  }
}
