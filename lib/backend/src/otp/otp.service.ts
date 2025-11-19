import { Inject, Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import * as argon2 from 'argon2';
import { PrismaService } from '../prisma/prisma.service';

type Purpose = 'RESET_PASSWORD' | 'VERIFY_CONTACT';

@Injectable()
export class OtpService {
  private transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: process.env.SMTP_SECURE === 'true',
    auth: (process.env.SMTP_USER && process.env.SMTP_PASS) ? {
      user: process.env.SMTP_USER, pass: process.env.SMTP_PASS
    } : undefined,
  });

  constructor(
    @Inject(CACHE_MANAGER) private cache: Cache,
    private prisma: PrismaService,
  ) {}

  private key(to: string, purpose: Purpose) {
    return `otp:${purpose}:${to}`;
  }

  private genCode() {
    return String(Math.floor(100000 + Math.random() * 900000)); // 6 digits
  }

  async requestOtp(to: string, purpose: Purpose, ttlSec = 600) {
    const code = this.genCode();
    await this.cache.set(this.key(to, purpose), JSON.stringify({ code, attempts: 0 }), ttlSec);

    const from = process.env.SMTP_FROM || 'no-reply@vethome.local';
    await this.transporter.sendMail({
      from, to,
      subject: purpose === 'RESET_PASSWORD' ? 'Réinitialisation du mot de passe' : 'Code de vérification',
      text: `Votre code est ${code} (valide 10 minutes).`,
      html: `<p>Votre code est <b>${code}</b> (valide 10 minutes).</p>`,
    });
    return { ok: true };
  }

  async verifyOtp(to: string, purpose: Purpose, code: string) {
    const raw = await this.cache.get<string>(this.key(to, purpose));
    if (!raw) return { ok: false, reason: 'expired' };
    const val = JSON.parse(raw) as { code: string; attempts: number };
    if (val.attempts >= 5) return { ok: false, reason: 'too_many_attempts' };
    if (val.code !== code) {
      await this.cache.set(this.key(to, purpose), JSON.stringify({ code: val.code, attempts: val.attempts + 1 }), 600);
      return { ok: false, reason: 'invalid' };
    }
    await this.cache.del(this.key(to, purpose));
    return { ok: true };
  }

  async resetPassword(to: string, code: string, newPassword: string) {
    const v = await this.verifyOtp(to, 'RESET_PASSWORD', code);
    if (!v.ok) return v;
    const user = await this.prisma.user.findUnique({ where: { email: to } });
    if (!user) return { ok: false, reason: 'user_not_found' };
    const hash = await argon2.hash(newPassword);
    await this.prisma.user.update({ where: { id: user.id }, data: { password: hash } });
    return { ok: true };
  }
}
