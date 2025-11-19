// src/providers/dto.ts
import { IsInt, IsNotEmpty, IsOptional, IsPositive, Min, IsString } from 'class-validator';

export class CreateServiceDto {
  @IsString()
  @IsNotEmpty()
  title!: string;

  @IsInt()
  @Min(15, { message: 'durationMin must be >= 15' })
  durationMin!: number;

  @IsOptional()
  @IsInt()
  @IsPositive()
  price?: number; // DA (optionnel)

  @IsOptional()
  @IsString()
  description?: string;
}

export class UpdateServiceDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  title?: string;

  @IsOptional()
  @IsInt()
  @Min(15)
  durationMin?: number;

  @IsOptional()
  @IsInt()
  @IsPositive()
  price?: number;

  @IsOptional()
  @IsString()
  description?: string;
}
