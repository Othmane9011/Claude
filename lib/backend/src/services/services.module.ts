import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ServicesService } from './services.service';
import { MyServicesController, ServicesCrudController } from './services.controller';

@Module({
  imports: [PrismaModule],
  controllers: [MyServicesController, ServicesCrudController],
  providers: [ServicesService],
})
export class ServicesModule {}
