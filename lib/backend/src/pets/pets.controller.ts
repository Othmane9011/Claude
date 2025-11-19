// src/pets/pets.controller.ts
import { Body, Controller, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { PetsService } from './pets.service';
import { JwtAuthGuard } from '../auth/guards/jwt.guard';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

@ApiTags('pets')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller({ path: 'pets', version: '1' })
export class PetsController {
  constructor(private readonly pets: PetsService) {}

  @Get('mine')
  listMine(@Req() req: any) {
    return this.pets.listMine(req.user.sub);
  }

  @Post()
  create(@Req() req: any, @Body() dto: any) {
    // debug utile si besoin
    // console.log('CREATE PET for user:', req.user.sub, 'payload:', dto);
    return this.pets.create(req.user.sub, dto);
  }

  @Patch(':id')
  update(@Req() req: any, @Param('id') id: string, @Body() dto: any) {
    return this.pets.update(req.user.sub, id, dto);
  }

  // Endpoint utilitaire pour réparer un pet mal rattaché
  @Patch(':id/reassign')
  reassign(@Req() req: any, @Param('id') id: string) {
    return this.pets.reassignToOwner(req.user.sub, id);
  }
}
