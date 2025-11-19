import { IsString, IsNotEmpty, IsInt, Min, Max, IsOptional } from 'class-validator';

export class CreateReviewDto {
  @IsString() @IsNotEmpty()
  bookingId!: string;

  @IsInt() @Min(1) @Max(5)
  rating!: number;

  @IsOptional()
  comment?: string;
}
