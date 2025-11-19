import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, PrismaClient } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateServiceDto, UpdateServiceDto } from './services.dto';

@Injectable()
export class ServicesService {
  constructor(private readonly prisma: PrismaService) {}

  private async getProviderIdForUser(userId: string) {
    const prov = await this.prisma.providerProfile.findUnique({ where: { userId } });
    if (!prov) throw new NotFoundException('Provider profile not found for current user');
    return prov.id;
  }

  async listMine(userId: string) {
    const providerId = await this.getProviderIdForUser(userId);
    return this.prisma.service.findMany({
      where: { providerId },
      orderBy: { title: 'asc' }, // le modèle Service n'a pas createdAt
    });
  }

  async createMine(userId: string, dto: CreateServiceDto) {
    const providerId = await this.getProviderIdForUser(userId);
    const price = dto.price ?? 0;

    return this.prisma.service.create({
      data: {
        providerId,
        title: dto.title,
        durationMin: dto.durationMin,
        description: dto.description ?? undefined,
        price: new Prisma.Decimal(price),
      },
    });
  }

  async updateMine(userId: string, id: string, dto: UpdateServiceDto) {
    const providerId = await this.getProviderIdForUser(userId);
    const svc = await this.prisma.service.findUnique({ where: { id } });
    if (!svc || svc.providerId !== providerId) {
      throw new NotFoundException('Service not found');
    }

    const data: Prisma.ServiceUpdateInput = {
      title: dto.title ?? undefined,
      durationMin: dto.durationMin ?? undefined,
      description: dto.description ?? undefined,
      price: dto.price != null ? new Prisma.Decimal(dto.price) : undefined,
    };

    return this.prisma.service.update({ where: { id }, data });
  }

  async deleteMine(userId: string, id: string) {
    const providerId = await this.getProviderIdForUser(userId);
    const svc = await this.prisma.service.findUnique({ where: { id } });
    if (!svc || svc.providerId !== providerId) {
      throw new NotFoundException('Service not found');
    }

    await this.prisma.service.delete({ where: { id } });
    return { success: true };
  }
}
