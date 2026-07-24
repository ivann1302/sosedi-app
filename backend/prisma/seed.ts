import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const categories = [
  { name: 'Дрели и шуруповерты', slug: 'dreli-i-shurupoverty', iconName: 'drill', sortOrder: 10 },
  { name: 'Перфораторы', slug: 'perforatory', iconName: 'hammer', sortOrder: 20 },
  { name: 'Пилы и лобзики', slug: 'pily-i-lobziki', iconName: 'saw', sortOrder: 30 },
  { name: 'Шлифовальные машины', slug: 'shlifovalnye-mashiny', iconName: 'disc', sortOrder: 40 },
  { name: 'Сварочное оборудование', slug: 'svarochnoe-oborudovanie', iconName: 'zap', sortOrder: 50 },
  { name: 'Компрессоры', slug: 'kompressory', iconName: 'gauge', sortOrder: 60 },
  { name: 'Лестницы и стремянки', slug: 'lestnicy-i-stremyanki', iconName: 'ladder', sortOrder: 70 },
  { name: 'Бетономешалки', slug: 'betonomeshalki', iconName: 'rotate-3d', sortOrder: 80 },
  { name: 'Измерительный инструмент', slug: 'izmeritelnyj-instrument', iconName: 'ruler', sortOrder: 90 },
  { name: 'Садовая техника', slug: 'sadovaya-tehnika', iconName: 'leaf', sortOrder: 100 },
];

async function main() {
  for (const category of categories) {
    await prisma.category.upsert({
      where: { slug: category.slug },
      update: category,
      create: category,
    });
  }
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
