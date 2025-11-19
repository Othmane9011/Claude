import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { JwtAuthGuard } from '../auth/guards/jwt.guard';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

@ApiTags('reviews')
@Controller({ path: 'reviews', version: '1' })
export class ReviewsController {
  constructor(private readonly svc: ReviewsService) {}

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Req() req: any, @Body() body: { bookingId: string; rating: number; comment?: string }) {
    return this.svc.create(req.user.sub, body.bookingId, body.rating, body.comment);
  }

  @Get('summary/provider')
  summaryProvider(@Body() body: { providerId: string }) { // pour Swagger test rapide
    return this.svc.providerSummary(body.providerId);
  }
}
