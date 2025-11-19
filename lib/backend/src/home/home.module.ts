import { Module } from '@nestjs/common';
import { HomeController } from './home.controller';
import { ProvidersModule } from '../providers/providers.module';

@Module({ imports: [ProvidersModule], controllers: [HomeController] })
export class HomeModule {}
