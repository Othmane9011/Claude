import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class CreateServiceDto {
  @IsString()
  title!: string;

  @IsInt()
  @Min(15)
  durationMin!: number;

  @IsOptional()
  @IsInt()
  price?: number; // store as integer DA (or convert to Decimal in service layer)

  @IsOptional()
  @IsString()
  description?: string;
}
