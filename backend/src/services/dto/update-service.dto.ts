import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class UpdateServiceDto {
  @IsOptional() @IsString() title?: string;
  @IsOptional() @IsInt() @Min(15) durationMin?: number;
  @IsOptional() @IsInt() @Min(0)  price?: number;
  @IsOptional() @IsString() description?: string;
}
