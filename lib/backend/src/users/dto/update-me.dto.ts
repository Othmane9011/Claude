import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsNumber } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateMeDto {
  @ApiPropertyOptional() @IsOptional() @IsString()
  firstName?: string;

  @ApiPropertyOptional() @IsOptional() @IsString()
  lastName?: string;

  @ApiPropertyOptional() @IsOptional() @IsString()
  phone?: string;

  @ApiPropertyOptional() @IsOptional() @IsString()
  city?: string;

  @ApiPropertyOptional() @IsOptional() @Type(() => Number) @IsNumber()
  lat?: number;

  @ApiPropertyOptional() @IsOptional() @Type(() => Number) @IsNumber()
  lng?: number;

  @ApiPropertyOptional() @IsOptional() @IsString()
  photoUrl?: string;
}
