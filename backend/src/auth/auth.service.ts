import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import * as argon2 from 'argon2';
import { ConfigService } from '@nestjs/config';
@Injectable()
export class AuthService {
  constructor(private prisma: PrismaService, private jwt: JwtService, private config: ConfigService) {}
  async register(email: string, password: string) {
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictException('Email already in use');
    const hash = await argon2.hash(password);
    const user = await this.prisma.user.create({ data: { email, password: hash }, select: { id: true, email: true, role: true, createdAt: true } });
    const tokens = await this.issueTokens(user.id, user.role);
    return { user, ...tokens };
  }
  async login(email: string, password: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) throw new UnauthorizedException('Invalid credentials');
    const ok = await argon2.verify(user.password, password);
    if (!ok) throw new UnauthorizedException('Invalid credentials');
    const tokens = await this.issueTokens(user.id, user.role);
    return { user: { id: user.id, email: user.email, role: user.role }, ...tokens };
  }
  async refresh(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new UnauthorizedException();
    const tokens = await this.issueTokens(user.id, user.role);
    return tokens;
  }
  private async issueTokens(userId: string, role: string) {
    const accessTtl = this.config.get<string>('JWT_ACCESS_TTL', '900s');
    const refreshTtl = this.config.get<string>('JWT_REFRESH_TTL', '7d');
    const access = await this.jwt.signAsync({ sub: userId, role }, { secret: this.config.get<string>('JWT_ACCESS_SECRET')!, expiresIn: accessTtl });
    const refresh = await this.jwt.signAsync({ sub: userId, typ: 'refresh' }, { secret: this.config.get<string>('JWT_REFRESH_SECRET')!, expiresIn: refreshTtl });
    return { accessToken: access, refreshToken: refresh };
  }
}
