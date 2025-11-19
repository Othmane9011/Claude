// src/config/config.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule as NestConfigModule } from '@nestjs/config';
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().min(1),
  JWT_ACCESS_SECRET: z.string().min(16),
  JWT_REFRESH_SECRET: z.string().min(16),
  JWT_ACCESS_TTL: z.string().default('900s'),
  JWT_REFRESH_TTL: z.string().default('7d'),
  REDIS_URL: z.string().url().optional(),
  CORS_ORIGINS: z.string().optional(),

  // Storage configuration
  STORAGE_PROVIDER: z.enum(['local', 's3']).default('local'),
  PUBLIC_URL: z.string().optional(),

  // S3 / OVH Object Storage
  AWS_REGION: z.string().default('gra'),
  S3_ENDPOINT: z.string().optional(),
  S3_BUCKET: z.string().optional(),
  S3_PUBLIC_ENDPOINT: z.string().optional(),
  AWS_ACCESS_KEY_ID: z.string().optional(),
  AWS_SECRET_ACCESS_KEY: z.string().optional(),
  S3_FORCE_PATH_STYLE: z.string().optional(),
  S3_USE_OBJECT_ACL: z.string().optional(),
});

export type Env = z.infer<typeof envSchema>;
export function validateEnv(config: Record<string, unknown>) {
  const parsed = envSchema.safeParse(config);
  if (!parsed.success) {
    console.error('❌ Invalid env:', parsed.error.flatten().fieldErrors);
    throw new Error('Invalid environment variables');
  }
  return parsed.data;
}

@Module({
  imports: [NestConfigModule.forRoot({ isGlobal: true, validate: validateEnv })],
})
export class ConfigModule {}
