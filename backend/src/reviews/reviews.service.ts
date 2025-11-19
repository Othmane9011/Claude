import { Injectable, BadRequestException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ReviewsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, bookingId: string, rating: number, comment?: string) {
    const booking = await this.prisma.booking.findUnique({ where: { id: bookingId } });
    if (!booking) throw new BadRequestException('Booking not found');
    if (booking.userId !== userId) throw new ForbiddenException();
    if (booking.status !== 'COMPLETED') throw new BadRequestException('Only completed bookings can be reviewed');

    const existing = await this.prisma.review.findUnique({ where: { bookingId } });
    if (existing) throw new BadRequestException('Already reviewed');

    return this.prisma.review.create({ data: { bookingId, userId, rating, comment: comment ?? null } });
  }

  providerSummary(providerId: string) {
    return this.prisma.review.aggregate({
      _avg: { rating: true },
      _count: { _all: true },
      where: { booking: { providerId } },
    });
  }
}
