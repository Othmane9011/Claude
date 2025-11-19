import { Body, Controller, Post } from '@nestjs/common';
import { OtpService } from './otp.service';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('otp')
@Controller({ path: 'auth', version: '1' })
export class OtpController {
  constructor(private readonly otp: OtpService) {}

  @Post('request-otp')
  request(@Body() body: { to: string; purpose: 'RESET_PASSWORD'|'VERIFY_CONTACT' }) {
    return this.otp.requestOtp(body.to, body.purpose);
  }

  @Post('verify-otp')
  verify(@Body() body: { to: string; purpose: 'RESET_PASSWORD'|'VERIFY_CONTACT'; code: string }) {
    return this.otp.verifyOtp(body.to, body.purpose, body.code);
  }

  @Post('reset-password')
  reset(@Body() body: { to: string; code: string; newPassword: string }) {
    return this.otp.resetPassword(body.to, body.code, body.newPassword);
  }
}
