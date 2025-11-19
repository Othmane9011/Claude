import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsInt, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class FeedQueryDto {
  @ApiPropertyOptional() @IsOptional() @IsString()
  cursor?: string; // id de post (pagination)

  @ApiPropertyOptional({ default: 20 }) @IsOptional() @IsInt() @Min(1) @Max(100)
  limit?: number = 20;

  @ApiPropertyOptional() @IsOptional() @IsNumber()
  lat?: number;

  @ApiPropertyOptional() @IsOptional() @IsNumber()
  lng?: number;

  @ApiPropertyOptional({ default: 40000 }) @IsOptional() @IsNumber()
  radiusKm?: number = 40000;

  @ApiPropertyOptional() @IsOptional() @IsString()
  species?: string;

  @ApiPropertyOptional() @IsOptional() @IsString()
  sex?: string;
}
