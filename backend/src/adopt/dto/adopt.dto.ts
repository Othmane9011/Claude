// src/adopt/dto/adopt.dto.ts
import {
  IsArray,
  ArrayMinSize,
  IsIn,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsInt,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

// -------- Création d’annonce --------
export class CreateAdoptListingDto {
  @IsString()
  @IsNotEmpty()
  petName!: string;

  @IsString()
  @IsNotEmpty()
  species!: string;

  @IsString()
  @IsNotEmpty()
  city!: string;

  @IsArray()
  @ArrayMinSize(1)
  @IsString({ each: true })
  photos!: string[];

  @IsOptional()
  @IsIn(['M', 'F', 'U'])
  sex?: 'M' | 'F' | 'U';

  @IsOptional()
  @IsString()
  age?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lat?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lng?: number;

  @IsOptional()
  @IsString()
  desc?: string;
}

// -------- Query feed public (Tinder) --------
export class AdoptFeedQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lat?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lng?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number;

  @IsOptional()
  @IsString()
  cursor?: string;
}

// -------- Query liste admin --------
export class AdminAdoptListQueryDto {
  @IsOptional()
  @IsIn(['PENDING', 'APPROVED', 'REJECTED', 'ARCHIVED'])
  status?: 'PENDING' | 'APPROVED' | 'REJECTED' | 'ARCHIVED';

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number;

  @IsOptional()
  @IsString()
  cursor?: string;
}

// -------- Body rejet admin --------
export class AdminRejectAdoptDto {
  @IsOptional()
  @IsString()
  reason?: string;
}

// -------- Body swipe (like / pass) --------
export class SwipeAdoptDto {
  @IsString()
  @IsIn(['like', 'pass'])
  action!: 'like' | 'pass';
}
