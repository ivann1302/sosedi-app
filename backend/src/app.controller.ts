import { Controller, Get, Header } from '@nestjs/common';
import { ApiExtraModels } from '@nestjs/swagger';
import {
  AppService,
  type HealthResponse,
  type ReadinessResponse,
} from './app.service';
import {
  BookingStatusDto,
  DisputeStatusDto,
  PaymentStatusDto,
  PayoutStatusDto,
} from './common/domain/workflow-status.dto';
import { ok } from './common/http/api-response';
import type { ApiResponse } from './common/http/api-response';

@ApiExtraModels(
  BookingStatusDto,
  PaymentStatusDto,
  PayoutStatusDto,
  DisputeStatusDto,
)
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('health')
  @Header('Cache-Control', 'no-store')
  getHealth(): ApiResponse<HealthResponse> {
    return ok(this.appService.getHealth());
  }

  @Get('health/live')
  @Header('Cache-Control', 'no-store')
  getLiveness(): ApiResponse<HealthResponse> {
    return ok(this.appService.getLiveness());
  }

  @Get('health/ready')
  @Header('Cache-Control', 'no-store')
  async getReadiness(): Promise<ApiResponse<ReadinessResponse>> {
    return ok(await this.appService.getReadiness());
  }
}
