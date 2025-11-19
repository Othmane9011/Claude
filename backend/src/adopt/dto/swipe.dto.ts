import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsEnum } from 'class-validator';

export enum SwipeAction {
  LIKE = 'LIKE',
  PASS = 'PASS',
}

export class SwipeDto {
  @ApiProperty({ enum: SwipeAction })
  @Transform(({ value }) => String(value ?? '').toUpperCase())
  @IsEnum(SwipeAction)
  action!: SwipeAction;
}
