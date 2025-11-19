// src/adopt/adopt.admin.controller.ts
import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Query,
  UseGuards,
  Injectable,
  CanActivate,
  ExecutionContext,
  ParseEnumPipe,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AdoptService } from './adopt.service';
import { AuthGuard } from '@nestjs/passport';
import { AdoptStatus } from '@prisma/client';

@Injectable()
class AdminOnlyGuard implements CanActivate {
  canActivate(ctx: ExecutionContext): boolean {
    const req = ctx.switchToHttp().getRequest();
    const role = req?.user?.role;
    return role === 'ADMIN' || role === 'admin';
  }
}

@ApiTags('AdoptAdmin')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AdminOnlyGuard)
@Controller({ path: 'admin/adopt', version: '1' })
export class AdoptAdminController {
  constructor(private readonly service: AdoptService) {}

  @Get('posts')
  async list(
    @Query('status', new ParseEnumPipe(AdoptStatus, { optional: true })) status?: AdoptStatus,
    @Query('limit', new ParseIntPipe({ optional: true })) limit?: number,
    @Query('cursor') cursor?: string,
  ) {
    return this.service.adminList(status, limit ?? 30, cursor);
  }

  @Patch('posts/:id/approve')
  async approve(@Param('id') id: string) {
    return this.service.adminApprove(null as any, id);
  }

  @Patch('posts/:id/reject')
  async reject(@Param('id') id: string, @Body() body: { note?: string }) {
    return this.service.adminReject(null as any, id, body?.note);
  }

  @Patch('posts/:id/archive')
  async archive(@Param('id') id: string) {
    return this.service.adminArchive(null as any, id);
  }
}
