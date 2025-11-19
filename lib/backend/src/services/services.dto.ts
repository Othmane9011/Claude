import { IsInt, IsOptional, IsPositive, IsString, Min } from 'class-validator';

export class CreateServiceDto {
  @IsString()
  title!: string;

  @IsInt()
  @Min(15)
  durationMin!: number;

  @IsOptional()
  @IsInt()
  @IsPositive()
  price?: number;

  @IsOptional()
  @IsString()
  description?: string;
}

export class UpdateServiceDto {
  @IsOptional() @IsString()
  title?: string;

  @IsOptional() @IsInt() @Min(15)
  durationMin?: number;

  @IsOptional() @IsInt() @IsPositive()
  price?: number;

  @IsOptional() @IsString()
  description?: string;
}
