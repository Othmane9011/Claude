import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { PetshopService } from './petshop.service';
import { PetshopController, ProvidersPetshopController, PublicPetshopController } from './petshop.controller';

@Module({
  imports: [PrismaModule],
  controllers: [PetshopController, ProvidersPetshopController, PublicPetshopController],
  providers: [PetshopService],
  exports: [PetshopService],
})
export class PetshopModule {}

