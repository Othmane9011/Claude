import { IsString, IsOptional, IsNumber, IsNotEmpty } from 'class-validator';

export class CreateBookingDto {
  @IsString() @IsNotEmpty()
  serviceId!: string;

  @IsOptional() @IsString()
  scheduledAt?: string;

  @IsOptional() @IsNumber()
  scheduledAtTs?: number;
}
