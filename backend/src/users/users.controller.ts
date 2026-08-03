import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ok, type ApiResponse } from '../common/http/api-response';
import { AuthService } from '../auth/auth.service';
import { CreateUserDataExportDto } from './dto/create-user-data-export.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import {
  UserDataExportService,
  type UserDataExport,
} from './user-data-export.service';
import { UserBlockResponseDto } from './dto/user-block-response.dto';
import { UsersService } from './users.service';
import type {
  AccountClosureResponse,
  UserUnblockResponse,
  UserProfileResponse,
} from './users.service';

@ApiTags('users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(
    private readonly users: UsersService,
    private readonly auth: AuthService,
    private readonly dataExport: UserDataExportService,
  ) {}

  @Get('me')
  async me(
    @CurrentUser() user: AuthUser,
  ): Promise<ApiResponse<UserProfileResponse>> {
    return ok(await this.users.getMe(user.id));
  }

  @Patch('me')
  async updateMe(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpdateProfileDto,
  ): Promise<ApiResponse<UserProfileResponse>> {
    return ok(await this.users.updateMe(user.id, dto));
  }

  @Post('me/data-export')
  async exportMyData(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateUserDataExportDto,
  ): Promise<ApiResponse<UserDataExport>> {
    await this.auth.consumeUserStepUpToken(
      dto.stepUpToken,
      user.id,
      'DATA_EXPORT',
    );
    return ok(await this.dataExport.create(user.id));
  }

  @Get('blocks')
  async listBlockedUsers(
    @CurrentUser() user: AuthUser,
  ): Promise<ApiResponse<UserBlockResponseDto[]>> {
    return ok(await this.users.listBlockedUsers(user.id));
  }

  @Post('blocks/:targetUserId')
  async blockUser(
    @CurrentUser() user: AuthUser,
    @Param('targetUserId', ParseUUIDPipe) targetUserId: string,
  ): Promise<ApiResponse<UserBlockResponseDto>> {
    return ok(await this.users.blockUser(user.id, targetUserId));
  }

  @Delete('blocks/:targetUserId')
  async unblockUser(
    @CurrentUser() user: AuthUser,
    @Param('targetUserId', ParseUUIDPipe) targetUserId: string,
  ): Promise<ApiResponse<UserUnblockResponse>> {
    return ok(await this.users.unblockUser(user.id, targetUserId));
  }

  @Delete('me')
  async deleteMe(
    @CurrentUser() user: AuthUser,
  ): Promise<ApiResponse<AccountClosureResponse>> {
    return ok(await this.users.deleteMe(user.id));
  }
}
