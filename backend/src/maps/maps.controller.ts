// src/maps/maps.controller.ts
import { Controller, Post, Body } from '@nestjs/common';
import { MapsService } from './maps.service';

@Controller('v1/maps')
export class MapsController {
  constructor(private readonly maps: MapsService) {}

  @Post('expand')
  async expand(@Body('url') url: string) {
    const res = await this.maps.expandAndParse(url, false);
    return res ?? {};
  }
}
