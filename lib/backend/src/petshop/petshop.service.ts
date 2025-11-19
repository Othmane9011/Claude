import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';

@Injectable()
export class PetshopService {
  constructor(private readonly prisma: PrismaService) {}

  private async getProviderIdForUser(userId: string) {
    // Validation: userId doit être défini
    if (!userId) {
      throw new BadRequestException('User ID is missing. Please ensure you are authenticated.');
    }

    const prov = await this.prisma.providerProfile.findUnique({
      where: { userId },
      select: { id: true, specialties: true },
    });
    if (!prov) throw new NotFoundException('Provider profile not found for current user');

    // Vérifier que c'est bien un petshop
    const kind = (prov.specialties as any)?.kind;
    if (kind !== 'petshop') {
      throw new BadRequestException('This endpoint is only available for petshop providers');
    }

    return prov.id;
  }

  // ========= Products =========

  async listMyProducts(userId: string) {
    const providerId = await this.getProviderIdForUser(userId);
    return this.prisma.product.findMany({
      where: { providerId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createProduct(userId: string, dto: CreateProductDto) {
    const providerId = await this.getProviderIdForUser(userId);

    return this.prisma.product.create({
      data: {
        providerId,
        title: dto.title,
        description: dto.description,
        priceDa: dto.priceDa,
        stock: dto.stock ?? undefined,
        category: dto.category ?? undefined,
        imageUrls: dto.imageUrls ? (dto.imageUrls as any) : undefined,
        active: dto.active ?? true,
      },
    });
  }

  async updateProduct(userId: string, productId: string, dto: UpdateProductDto) {
    const providerId = await this.getProviderIdForUser(userId);
    const product = await this.prisma.product.findUnique({ where: { id: productId } });
    if (!product || product.providerId !== providerId) {
      throw new NotFoundException('Product not found');
    }

    const data: Prisma.ProductUpdateInput = {
      title: dto.title ?? undefined,
      description: dto.description ?? undefined,
      priceDa: dto.priceDa ?? undefined,
      stock: dto.stock ?? undefined,
      category: dto.category ?? undefined,
      imageUrls: dto.imageUrls ? (dto.imageUrls as any) : undefined,
      active: dto.active ?? undefined,
    };

    return this.prisma.product.update({ where: { id: productId }, data });
  }

  async deleteProduct(userId: string, productId: string) {
    const providerId = await this.getProviderIdForUser(userId);
    const product = await this.prisma.product.findUnique({ where: { id: productId } });
    if (!product || product.providerId !== providerId) {
      throw new NotFoundException('Product not found');
    }

    await this.prisma.product.delete({ where: { id: productId } });
    return { success: true };
  }

  // ========= Orders =========

  private buildDisplayName(user: { firstName?: string | null; lastName?: string | null; email: string }): string {
    const parts = [user.firstName, user.lastName].filter(Boolean);
    return parts.length > 0 ? parts.join(' ') : user.email.split('@')[0];
  }

  async listMyOrders(userId: string, status?: string) {
    const providerId = await this.getProviderIdForUser(userId);

    const where: Prisma.OrderWhereInput = {
      providerId,
      ...(status && status !== 'ALL' ? { status: status as any } : {}),
    };

    const orders = await this.prisma.order.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            phone: true,
          },
        },
        items: {
          include: {
            product: {
              select: {
                id: true,
                title: true,
                imageUrls: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });

    // Ajouter displayName pour chaque order
    return orders.map((order: any) => ({
      ...order,
      user: {
        ...order.user,
        displayName: this.buildDisplayName(order.user),
      },
    }));
  }

  async getOrder(userId: string, orderId: string) {
    const providerId = await this.getProviderIdForUser(userId);

    const order = await this.prisma.order.findFirst({
      where: {
        id: orderId,
        providerId,
      },
      include: {
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            phone: true,
          },
        },
        items: {
          include: {
            product: {
              select: {
                id: true,
                title: true,
                description: true,
                imageUrls: true,
              },
            },
          },
        },
      },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    // Ajouter displayName
    return {
      ...order,
      user: {
        ...order.user,
        displayName: this.buildDisplayName(order.user),
      },
    };
  }

  async updateOrderStatus(userId: string, orderId: string, status: string) {
    const providerId = await this.getProviderIdForUser(userId);

    const order = await this.prisma.order.findFirst({
      where: {
        id: orderId,
        providerId,
      },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    return this.prisma.order.update({
      where: { id: orderId },
      data: { status: status as any },
    });
  }

  // ========= Public endpoints =========

  async listPublicProducts(providerId: string) {
    // Vérifier que le provider existe et est un petshop
    const prov = await this.prisma.providerProfile.findUnique({
      where: { id: providerId },
      select: { id: true, specialties: true, isApproved: true },
    });

    if (!prov) {
      throw new NotFoundException('Provider not found');
    }

    if (!prov.isApproved) {
      throw new NotFoundException('Provider not approved');
    }

    const kind = (prov.specialties as any)?.kind;
    if (kind !== 'petshop') {
      throw new BadRequestException('This provider is not a petshop');
    }

    // Retourner uniquement les produits actifs
    return this.prisma.product.findMany({
      where: {
        providerId,
        active: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}

