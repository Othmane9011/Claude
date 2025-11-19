// import { PrismaClient, Prisma } from '@prisma/client';
// import * as argon2 from 'argon2';

// const prisma = new PrismaClient();
// const hash = (pwd: string) => argon2.hash(pwd);

// async function main() {
//   // --- Users ---
//   const admin = await prisma.user.upsert({
//     where: { email: 'admin@vethome.local' },
//     update: {},
//     create: {
//       email: 'admin@vethome.local',
//       password: await hash('admin123'),
//       role: 'ADMIN',
//       firstName: 'Admin',
//     },
//   });

//   const proUser = await prisma.user.upsert({
//     where: { email: 'pro1@vethome.local' },
//     update: { role: 'PRO' },
//     create: {
//       email: 'pro1@vethome.local',
//       password: await hash('pass1234'),
//       role: 'PRO',
//       firstName: 'Pro',
//       lastName: 'One',
//     },
//   });

//   const client = await prisma.user.upsert({
//     where: { email: 'user1@vethome.local' },
//     update: {},
//     create: {
//       email: 'user1@vethome.local',
//       password: await hash('pass1234'),
//       role: 'USER',
//       firstName: 'User',
//       lastName: 'One',
//     },
//   });

//   // // --- Provider profile ---
//   // const provider = await prisma.providerProfile.upsert({
//   //   where: { userId: proUser.id },
//   //   update: {
//   //     displayName: 'Dr. VetHome',
//   //     bio: 'Spécialiste NAC',
//   //     address: 'Alger Centre',
//   //     lat: 36.75,
//   //     lng: 3.06,
//   //     timezone: 'Europe/Paris',
//   //     specialties: { species: ['Chat', 'Chien', 'NAC'] },
//   //   },
//   //   create: {
//   //     userId: proUser.id,
//   //     displayName: 'Dr. VetHome',
//   //     bio: 'Spécialiste NAC',
//   //     address: 'Alger Centre',
//   //     lat: 36.75,
//   //     lng: 3.06,
//   //     timezone: 'Europe/Paris',
//   //     specialties: { species: ['Chat', 'Chien', 'NAC'] },
//   //   },
//   // });

//   // // --- Weekly availability (lun–ven 09:00–12:00 & 14:00–18:00) ---
//   // await prisma.providerAvailability.deleteMany({ where: { providerId: provider.id } });
//   // const day = (d: number, sH: number, sM: number, eH: number, eM: number) => ({
//   //   providerId: provider.id,
//   //   weekday: d, // 1=Mon..7=Sun (ici 1..5)
//   //   startMin: sH * 60 + sM,
//   //   endMin: eH * 60 + eM,
//   //   timezone: provider.timezone ?? 'UTC',
//   // });
//   // await prisma.providerAvailability.createMany({
//   //   data: [
//   //     day(1, 9, 0, 12, 0), day(1, 14, 0, 18, 0),
//   //     day(2, 9, 0, 12, 0), day(2, 14, 0, 18, 0),
//   //     day(3, 9, 0, 12, 0), day(3, 14, 0, 18, 0),
//   //     day(4, 9, 0, 12, 0), day(4, 14, 0, 18, 0),
//   //     day(5, 9, 0, 12, 0), day(5, 14, 0, 18, 0),
//   //   ],
//   // });

//   // // --- Service (idempotent) ---
//   // let service = await prisma.service.findFirst({
//   //   where: { providerId: provider.id, title: 'Consultation' },
//   // });
//   // if (!service) {
//   //   service = await prisma.service.create({
//   //     data: {
//   //       providerId: provider.id,
//   //       title: 'Consultation',
//   //       description: '30 minutes',
//   //       price: new Prisma.Decimal('2500.00'),
//   //       durationMin: 30,
//   //     },
//   //   });
//   // }

//   // // --- Pet de test pour le client ---
//   // await prisma.pet.upsert({
//   //   where: { id: 'seed-pet-1' },
//   //   update: { name: 'Moka', gender: 'FEMALE', color: 'Noir', country: 'DZ' },
//   //   create: {
//   //     id: 'seed-pet-1',
//   //     ownerId: client.id,
//   //     name: 'Moka',
//   //     gender: 'FEMALE',
//   //     color: 'Noir',
//   //     country: 'DZ',
//   //   },
//   // });

//   // console.log('✅ Seed done:', {
//   //   admin: admin.email,
//   //   pro: proUser.email,
//   //   client: client.email,
//   //   providerId: provider.id,
//   //   serviceId: service.id,
//   // });
// }

// main()
//   .catch((e) => { console.error(e); process.exit(1); })
//   .finally(async () => { await prisma.$disconnect(); });
