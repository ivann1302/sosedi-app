import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiCookieAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { AdminCapability } from '@prisma/client';
import { AdminCapabilities } from '../admin/admin-capabilities.decorator';
import { getAdminAuditContext } from '../admin/admin-audit-context';
import { AdminSessionGuard } from '../admin/admin-session.guard';
import { ADMIN_SESSION_COOKIE } from '../admin/admin-session.service';
import type { AuthenticatedRequest, AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { ok, type ApiResponse } from '../common/http/api-response';
import { DecideReportDto } from './dto/decide-report.dto';
import { ReportsService, type AdminReportResponse } from './reports.service';

@ApiTags('admin-reports')
@ApiCookieAuth(ADMIN_SESSION_COOKIE)
@AdminCapabilities(AdminCapability.MODERATION)
@UseGuards(AdminSessionGuard)
@Controller('admin/reports')
export class AdminReportsController {
  constructor(private readonly reports: ReportsService) {}

  @ApiOkResponse({ description: 'Очередь открытых UGC-жалоб' })
  @Get()
  async list(): Promise<ApiResponse<AdminReportResponse[]>> {
    return ok(await this.reports.listOpenForAdmin());
  }

  @ApiOkResponse({ description: 'Результат решения по жалобе' })
  @Patch(':id/decision')
  async decide(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: DecideReportDto,
  ): Promise<ApiResponse<AdminReportResponse>> {
    return ok(
      await this.reports.decide(
        user.id,
        id,
        dto,
        getAdminAuditContext(request),
      ),
    );
  }
}
