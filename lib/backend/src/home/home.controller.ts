import { Controller, Get, Query } from '@nestjs/common';
import { ProvidersService } from '../providers/providers.service';

@Controller({ path: 'home', version: '1' })
export class HomeController {
  constructor(private providers: ProvidersService) {}

  @Get()
  async get(@Query('lat') lat?: string, @Query('lng') lng?: string) {
    const nearby = (lat && lng) ? await this.providers.nearby(Number(lat), Number(lng), 15, 8, 0) : [];
    return {
      categories: ['Généraliste','NAC','Chirurgie','Dermato','Dentisterie','Imagerie'],
      vethub: [{ id: 'article-1', title: 'Soins post-op NAC' }, { id: 'article-2', title: 'Vermifuges: bien choisir' }],
      top: nearby,
    };
  }
}
