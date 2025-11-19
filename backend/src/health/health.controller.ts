import { Controller, Get } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Cache } from 'cache-manager';
import { Inject } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';

@Controller({ path: 'health', version: '1' })
export class HealthController {
  constructor(
    private prisma: PrismaService,
    @Inject(CACHE_MANAGER) private cache: Cache,
  ) {}

  @Get()
  async check() {
    // DB
    let db = 'down';
    try { await this.prisma.$queryRawUnsafe('SELECT 1'); db = 'up'; } catch {}

    // Redis
    let redis = 'down';
    try {
      await this.cache.set('health:ping', 'pong', 2);
      const v = await this.cache.get('health:ping');
      if (v === 'pong') redis = 'up';
    } catch {}

    return { status: db === 'up' && redis === 'up' ? 'ok' : 'degraded', db, redis };
  }
}
