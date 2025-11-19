import { Body, Controller, Get, HttpCode, HttpStatus, Post, Req, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength } from 'class-validator';
import { JwtAuthGuard } from './guards/jwt.guard';
class RegisterDto { @IsEmail() email!: string; @IsString() @MinLength(6) password!: string; }
class LoginDto { @IsEmail() email!: string; @IsString() @MinLength(6) password!: string; }
@ApiTags('auth')
@Controller({ path: 'auth', version: '1' })
export class AuthController {
  constructor(private readonly auth: AuthService) {}
  @Post('register') async register(@Body() dto: RegisterDto) { return this.auth.register(dto.email, dto.password); }
  @HttpCode(HttpStatus.OK) @Post('login') async login(@Body() dto: LoginDto) { return this.auth.login(dto.email, dto.password); }
  @ApiBearerAuth() @UseGuards(JwtAuthGuard) @Get('me') async me(@Req() req: any) { return req.user; }
  @ApiBearerAuth() @UseGuards(JwtAuthGuard) @Post('refresh') async refresh(@Req() req: any) { return this.auth.refresh(req.user.sub); }
}
