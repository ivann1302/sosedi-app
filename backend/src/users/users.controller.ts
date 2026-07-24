import {
  Body,
  Controller,
  Delete,
  Get,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ok, type ApiResponse } from '../common/http/api-response';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UsersService } from './users.service';
import type {
  DeleteProfileResponse,
  UserProfileResponse,
} from './users.service';

@ApiTags('users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly users: UsersService) {}

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

  @Delete('me')
  async deleteMe(
    @CurrentUser() user: AuthUser,
  ): Promise<ApiResponse<DeleteProfileResponse>> {
    return ok(await this.users.deleteMe(user.id));
  }
}
