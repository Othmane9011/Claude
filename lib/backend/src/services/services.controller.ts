import {
  Body, Controller, Delete, Get, Param, Patch, Post, Put, UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt.guard';
import { ReqUser } from '../auth/req-user.decorator';
import { ServicesService } from './services.service';
import { CreateServiceDto, UpdateServiceDto } from './services.dto';

/**
 * Liste + création: /providers/me/services
 */
@UseGuards(JwtAuthGuard)
@Controller('providers/me/services')
export class MyServicesController {
  constructor(private readonly services: ServicesService) {}

  @Get()
  listMine(@ReqUser() user: { id: string }) {
    return this.services.listMine(user.id);
  }

  @Post()
  createMine(@ReqUser() user: { id: string }, @Body() dto: CreateServiceDto) {
    return this.services.createMine(user.id, dto);
  }

  // Si ton front utilise encore /providers/me/services/:id -> on les expose aussi
  @Patch(':id')
  updateMineOnProviders(
    @ReqUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: UpdateServiceDto,
  ) {
    return this.services.updateMine(user.id, id, dto);
  }

  @Delete(':id')
  deleteMineOnProviders(@ReqUser() user: { id: string }, @Param('id') id: string) {
    return this.services.deleteMine(user.id, id);
  }
}

/**
 * CRUD direct: /services/:id
 * (tes logs montrent PATCH/PUT/DELETE /api/v1/services/:id → on les ajoute)
 */
@UseGuards(JwtAuthGuard)
@Controller('services')
export class ServicesCrudController {
  constructor(private readonly services: ServicesService) {}

  @Patch(':id')
  patch(
    @ReqUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: UpdateServiceDto,
  ) {
    return this.services.updateMine(user.id, id, dto);
  }

  @Put(':id')
  put(
    @ReqUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: UpdateServiceDto,
  ) {
    return this.services.updateMine(user.id, id, dto);
  }

  @Delete(':id')
  delete(@ReqUser() user: { id: string }, @Param('id') id: string) {
    return this.services.deleteMine(user.id, id);
  }
}
