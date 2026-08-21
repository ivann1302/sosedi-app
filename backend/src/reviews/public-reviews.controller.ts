import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { ok, type ApiResponse } from '../common/http/api-response';
import { ListReviewsQueryDto } from './dto/list-reviews-query.dto';
import { PublicReviewPageResponseDto } from './dto/review-response.dto';
import { ReviewsService } from './reviews.service';

@ApiTags('reviews')
@Controller('users/:targetUserId/reviews')
export class PublicReviewsController {
  constructor(private readonly reviews: ReviewsService) {}

  @ApiOkResponse({ type: PublicReviewPageResponseDto })
  @Get()
  async list(
    @Param('targetUserId', ParseUUIDPipe) targetUserId: string,
    @Query() query: ListReviewsQueryDto,
  ): Promise<ApiResponse<PublicReviewPageResponseDto>> {
    return ok(await this.reviews.listPublicForUser(targetUserId, query));
  }
}
