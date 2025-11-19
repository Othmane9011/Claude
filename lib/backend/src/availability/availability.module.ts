import { Module } from '@nestjs/common';
import { AvailabilityService } from './availability.service';
import { AvailabilityController } from './availability.controller';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  imports: [],
  controllers: [AvailabilityController],     // tu peux enlever ce controller si tu ne l’utilises pas
  providers: [AvailabilityService, PrismaService],
  exports: [AvailabilityService],            // ← important : expose le service aux autres modules
})
export class AvailabilityModule {}
