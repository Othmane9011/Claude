// scripts/reset-admin.js
const { PrismaClient } = require('@prisma/client');
const argon2 = require('argon2');

(async () => {
  const prisma = new PrismaClient();
  const email = process.env.ADMIN_EMAIL || 'admin@vethome.local';
  const pass  = process.env.ADMIN_PASS  || 'pass1234';
  const makeAdmin = (process.env.MAKE_ADMIN || 'true') === 'true';

  console.log(`Reset password for ${email} ...`);
  const hash = await argon2.hash(pass);

  const user = await prisma.user.update({
    where: { email },
    data: { password: hash, ...(makeAdmin ? { role: 'ADMIN' } : {}) },
    select: { id: true, email: true, role: true },
  });

  console.log('Done:', user);
  await prisma.$disconnect();
})().catch((e) => { console.error(e); process.exit(1); });
