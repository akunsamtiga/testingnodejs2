const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function main() {
  console.log("🌱 Seeding database...");

  // Buat admin user
  const hashedPassword = await bcrypt.hash("admin123", 10);
  await prisma.user.create({
    data: {
      name: "Admin",
      email: "admin@example.com",
      password: hashedPassword,
      role: "ADMIN"
    }
  });

  // Buat user biasa
  await prisma.user.create({
    data: {
      name: "User Baru",
      email: "userbaru@example.com",
      password: await bcrypt.hash("password123", 10),
      role: "USER"
    }
  });

  // Buat beberapa produk
  await prisma.product.createMany({
    data: [
      { title: "Laptop Gaming", description: "Laptop high-end", price: 15000000, category: "Electronics", stock: 10 },
      { title: "Smartphone", description: "Handphone terbaru", price: 5000000, category: "Electronics", stock: 20 }
    ]
  });

  // Buat artikel
  await prisma.article.createMany({
    data: [
      { title: "Teknologi AI", content: "Artikel tentang AI", author: "Admin", published: true },
      { title: "Perkembangan Web", content: "Artikel tentang web", author: "Admin", published: true }
    ]
  });

  console.log("✅ Seeding selesai!");
}

main()
  .catch(e => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
