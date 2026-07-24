import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { KycStatus, Prisma, User, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

type UserProfileModel = Pick<
  User,
  | 'id'
  | 'phone'
  | 'name'
  | 'city'
  | 'avatarUrl'
  | 'role'
  | 'kycStatus'
  | 'isBlocked'
  | 'deletedAt'
  | 'createdAt'
  | 'updatedAt'
>;

export type UserProfileResponse = {
  id: string;
  phone: string;
  name: string | null;
  city: string | null;
  avatarUrl: string | null;
  role: UserRole;
  kycStatus: KycStatus | null;
  isBlocked: boolean;
  createdAt: Date;
  updatedAt: Date;
};

export type DeleteProfileResponse = {
  deleted: true;
};

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId: string): Promise<UserProfileResponse> {
    const user = await this.findActiveUser(userId);
    return this.toProfileResponse(user);
  }

  async updateMe(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<UserProfileResponse> {
    const currentUser = await this.findActiveUser(userId);
    const data = this.buildProfileUpdateData(dto);

    if (Object.keys(data).length === 0) {
      return this.toProfileResponse(currentUser);
    }

    const user = await this.prisma.user.update({
      where: { id: userId },
      data,
      select: this.userProfileSelect(),
    });

    return this.toProfileResponse(user);
  }

  async deleteMe(userId: string): Promise<DeleteProfileResponse> {
    await this.findActiveUser(userId);

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        phone: `deleted:${userId}`,
        name: null,
        city: null,
        avatarUrl: null,
        deletedAt: new Date(),
      },
    });

    return { deleted: true };
  }

  private async findActiveUser(userId: string): Promise<UserProfileModel> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: this.userProfileSelect(),
    });

    if (!user || user.deletedAt) {
      throw new NotFoundException('Пользователь не найден');
    }

    if (user.isBlocked) {
      throw new ForbiddenException('Пользователь заблокирован');
    }

    return user;
  }

  private buildProfileUpdateData(
    dto: UpdateProfileDto,
  ): Prisma.UserUpdateInput {
    const data: Prisma.UserUpdateInput = {};

    if (Object.hasOwn(dto, 'name')) {
      data.name = dto.name;
    }

    if (Object.hasOwn(dto, 'city')) {
      data.city = dto.city;
    }

    if (Object.hasOwn(dto, 'avatarUrl')) {
      data.avatarUrl = dto.avatarUrl;
    }

    return data;
  }

  private toProfileResponse(user: UserProfileModel): UserProfileResponse {
    return {
      id: user.id,
      phone: user.phone,
      name: user.name,
      city: user.city,
      avatarUrl: user.avatarUrl,
      role: user.role,
      kycStatus: user.kycStatus,
      isBlocked: user.isBlocked,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  private userProfileSelect() {
    return {
      id: true,
      phone: true,
      name: true,
      city: true,
      avatarUrl: true,
      role: true,
      kycStatus: true,
      isBlocked: true,
      deletedAt: true,
      createdAt: true,
      updatedAt: true,
    } as const;
  }
}
