import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ok, type ApiResponse } from '../common/http/api-response';
import {
  InboxEventDetailsResponseDto,
  InboxEventResponseDto,
} from './dto/inbox-event-response.dto';
import { InboxService } from './inbox.service';

@ApiTags('inbox')
@ApiBearerAuth()
@Roles(UserRole.USER)
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('inbox')
export class InboxController {
  constructor(private readonly inbox: InboxService) {}

  @ApiOkResponse({ type: [InboxEventResponseDto] })
  @Get()
  async list(
    @CurrentUser() user: AuthUser,
  ): Promise<ApiResponse<InboxEventResponseDto[]>> {
    return ok(await this.inbox.list(user.id));
  }

  @ApiOkResponse({ type: InboxEventDetailsResponseDto })
  @Get(':eventId')
  async getDetails(
    @CurrentUser() user: AuthUser,
    @Param('eventId', ParseUUIDPipe) eventId: string,
  ): Promise<ApiResponse<InboxEventDetailsResponseDto>> {
    return ok(await this.inbox.getDetails(user.id, eventId));
  }

  @ApiOkResponse({ type: InboxEventResponseDto })
  @Patch(':eventId/read')
  async markRead(
    @CurrentUser() user: AuthUser,
    @Param('eventId', ParseUUIDPipe) eventId: string,
  ): Promise<ApiResponse<InboxEventResponseDto>> {
    return ok(await this.inbox.markRead(user.id, eventId));
  }
}
