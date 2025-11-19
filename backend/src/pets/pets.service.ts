// src/pets/pets.service.ts
import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PetsService {
  constructor(private prisma: PrismaService) {}

  listMine(ownerId: string) {
    return this.prisma.pet.findMany({
      where: { ownerId },
      orderBy: { updatedAt: 'desc' },
    });
  }

  // ⚠️ ownerId imposé côté serveur, on ignore tout ownerId envoyé par le client
  create(ownerId: string, dto: any) {
    const data = {
      name: dto.name,
      gender: dto.gender,
      weightKg: dto.weightKg ?? null,
      color: dto.color ?? null,
      country: dto.country ?? null,
      idNumber: dto.idNumber ?? null,
      breed: dto.breed ?? null,
      neuteredAt: dto.neuteredAt ? new Date(dto.neuteredAt) : null,
      photoUrl: dto.photoUrl ?? null,
      ownerId, // <- ici on force
    };
    return this.prisma.pet.create({ data });
  }

  async update(ownerId: string, id: string, dto: any) {
    const pet = await this.prisma.pet.findUnique({ where: { id } });
    if (!pet) throw new NotFoundException('Pet not found');
    if (pet.ownerId !== ownerId) throw new ForbiddenException();

    const data: any = {
      name: dto.name ?? pet.name,
      gender: dto.gender ?? pet.gender,
      weightKg: dto.weightKg ?? pet.weightKg,
      color: dto.color ?? pet.color,
      country: dto.country ?? pet.country,
      idNumber: dto.idNumber ?? pet.idNumber,
      breed: dto.breed ?? pet.breed,
      photoUrl: dto.photoUrl ?? pet.photoUrl,
    };
    if (dto.neuteredAt !== undefined) {
      data.neuteredAt = dto.neuteredAt ? new Date(dto.neuteredAt) : null;
    }
    return this.prisma.pet.update({ where: { id }, data });
  }

  // Outil de réparation : rattache un pet existant à l’utilisateur courant
  async reassignToOwner(ownerId: string, petId: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException('Pet not found');
    return this.prisma.pet.update({
      where: { id: petId },
      data: { ownerId },
    });
  }
}
