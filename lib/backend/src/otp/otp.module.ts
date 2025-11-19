import { Module } from '@nestjs/common';
import { OtpService } from './otp.service';
import { OtpController } from './otp.controller';
import { CacheModule } from '@nestjs/cache-manager';

@Module({
  imports: [CacheModule.register()],
  controllers: [OtpController],
  providers: [OtpService],
  exports: [OtpService],
})
export class OtpModule {}
