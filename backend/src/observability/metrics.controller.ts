import {
  Controller,
  Get,
  Header,
  Headers,
  UnauthorizedException,
} from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import { MetricsService } from './metrics.service';

@ApiExcludeController()
@Controller('internal')
export class MetricsController {
  constructor(private readonly metrics: MetricsService) {}

  @Get('metrics')
  @Header('Cache-Control', 'no-store')
  @Header('Content-Type', 'text/plain; version=0.0.4; charset=utf-8')
  async getMetrics(
    @Headers('authorization') authorization?: string,
  ): Promise<string> {
    if (!this.metrics.isAuthorized(authorization)) {
      throw new UnauthorizedException('Metrics token is invalid');
    }

    return this.metrics.render();
  }
}
