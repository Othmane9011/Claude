// src/earnings/earnings.module.ts
import { Module } from '@nestjs/common';
import { EarningsController } from './earnings.controller';
import { EarningsService } from './earnings.service';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module'; // pour JwtAuthGuard/RolesGuard

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [EarningsController],
  providers: [EarningsService],
})
export class EarningsModule {}
