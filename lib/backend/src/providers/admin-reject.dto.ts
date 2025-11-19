import { IsOptional, IsString, MaxLength } from 'class-validator';
export class AdminRejectDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
