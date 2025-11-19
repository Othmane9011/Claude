import { Module } from '@nestjs/common';
import { ProvidersController } from './providers.controller';
import { ProvidersService } from './providers.service';
import { PrismaService } from '../prisma/prisma.service';
import { AvailabilityModule } from '../availability/availability.module';
import { MapsModule } from '../maps/maps.module';

@Module({
  imports: [AvailabilityModule, MapsModule],
  controllers: [ProvidersController],
  providers: [ProvidersService, PrismaService],
  exports: [ProvidersService],
})
export class ProvidersModule {}
