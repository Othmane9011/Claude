import { PrismaClient } from '@prisma/client';
import * as argon2 from 'argon2';
const prisma = new PrismaClient();
async function main() {
  const adminEmail = 'admin@vethome.local';
  const password = await argon2.hash('admin123');
  await prisma.user.upsert({
    where: { email: adminEmail },
    update: {},
    create: { email: adminEmail, password, role: 'ADMIN' },
  });
  console.log('Seed done');
}
main().catch((e) => { console.error(e); process.exit(1); }).finally(async () => { await prisma.$disconnect(); });
