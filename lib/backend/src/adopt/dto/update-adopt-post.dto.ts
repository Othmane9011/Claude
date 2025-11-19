import { PartialType } from '@nestjs/swagger';
import { CreateAdoptPostDto } from './create-adopt-post.dto';

export class UpdateAdoptPostDto extends PartialType(CreateAdoptPostDto) {}
