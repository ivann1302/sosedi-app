import { Controller, Get } from '@nestjs/common';
import { AppService, type HealthResponse } from './app.service';
import { ok } from './common/http/api-response';
import type { ApiResponse } from './common/http/api-response';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('health')
  getHealth(): ApiResponse<HealthResponse> {
    return ok(this.appService.getHealth());
  }
}
