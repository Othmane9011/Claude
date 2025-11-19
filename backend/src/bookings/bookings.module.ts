import { Module } from '@nestjs/common';
import { BookingsController } from './bookings.controller';
import { BookingsService } from './bookings.service';
import { AvailabilityModule } from '../availability/availability.module';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  imports: [AvailabilityModule],             // ← pour injecter AvailabilityService dans le controller
  controllers: [BookingsController],
  providers: [BookingsService, PrismaService],
  exports: [BookingsService],
})
export class BookingsModule {}
