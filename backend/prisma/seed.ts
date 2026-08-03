import { CategoryListingPolicy, PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const launchCategories = [
  {
    name: 'Проекторы и экраны',
    slug: 'proektory-i-ekrany',
    iconName: 'projector',
    sortOrder: 10,
    safetyNotice:
      'Перед передачей проверьте комплектность, кабели, крепления и исправность устройства.',
  },
  {
    name: 'Фото и видео',
    slug: 'foto-i-video',
    iconName: 'camera',
    sortOrder: 20,
    safetyNotice:
      'Перед передачей проверьте комплектность и аккумулятор, удалите личные данные с носителей.',
  },
  {
    name: 'Игровые приставки',
    slug: 'igrovye-pristavki',
    iconName: 'gamepad-2',
    sortOrder: 30,
    safetyNotice:
      'Перед передачей удалите платёжные данные и аккаунты, проверьте кабели и комплектность.',
  },
  {
    name: 'Настольные игры',
    slug: 'nastolnye-igry',
    iconName: 'dice-5',
    sortOrder: 40,
    safetyNotice:
      'Пересчитайте комплектность; не передавайте игры с повреждёнными или опасными мелкими деталями.',
  },
  {
    name: 'Музыкальные инструменты',
    slug: 'muzykalnye-instrumenty',
    iconName: 'music',
    sortOrder: 50,
    safetyNotice:
      'Проверьте исправность и комплектность; индивидуальные гигиенические насадки не передаются.',
  },
  {
    name: 'Швейные машины',
    slug: 'shvejnye-mashiny',
    iconName: 'scissors',
    sortOrder: 60,
    safetyNotice:
      'Перед передачей отключите питание, закройте иглу защитой и объясните безопасное использование.',
  },
];

const restrictedCategories = [
  {
    name: 'Электроинструменты, строительное и садовое оборудование',
    slug: 'elektroinstrumenty-i-oborudovanie',
  },
  {
    name: 'Транспорт и средства индивидуальной мобильности',
    slug: 'transport-i-sim',
  },
  {
    name: 'Спортивное, туристическое и водное снаряжение',
    slug: 'sport-turizm-i-voda',
  },
  {
    name: 'Детские товары и средства безопасности',
    slug: 'detskie-tovary-i-bezopasnost',
  },
  {
    name: 'Беспилотники и радиооборудование',
    slug: 'bespilotniki-i-radiooborudovanie',
  },
  {
    name: 'Медицинские изделия и средства реабилитации',
    slug: 'medicinskie-izdeliya-i-reabilitaciya',
  },
].map((category, index) => ({
  ...category,
  iconName: null,
  sortOrder: 200 + index * 10,
  safetyNotice:
    'Публикация закрыта до отдельной legal/safety проверки требований к допуску, состоянию и передаче.',
}));

const prohibitedCategories = [
  {
    name: 'Оружие, боеприпасы и средства самообороны',
    slug: 'oruzhie-i-boepripasy',
  },
  {
    name: 'Взрывчатые вещества, пиротехника, топливо и газовые баллоны',
    slug: 'vzryvchatye-veshchestva-i-pirotehnika',
  },
  {
    name: 'Наркотические, психотропные вещества и прекурсоры',
    slug: 'kontroliruemye-veshchestva',
  },
  {
    name: 'Лекарства, алкоголь, табак и никотинсодержащая продукция',
    slug: 'lekarstva-alkogol-i-tabak',
  },
  {
    name: 'Еда, расходники, косметика и бытовая химия',
    slug: 'rashodniki-kosmetika-i-himiya',
  },
  {
    name: 'Предметы личной гигиены и бельё',
    slug: 'lichnaya-gigiena',
  },
  {
    name: 'Документы, платёжные средства, аккаунты и цифровой доступ',
    slug: 'dokumenty-i-cifrovoj-dostup',
  },
  {
    name: 'Животные, растения, контрафактные и незаконно полученные вещи',
    slug: 'zhivotnye-kontrafakt-i-nezakonnye-veshchi',
  },
].map((category, index) => ({
  ...category,
  iconName: null,
  sortOrder: 400 + index * 10,
  safetyNotice: 'Публикация этой категории запрещена правилами площадки.',
}));

async function main() {
  const policyCategories = [
    ...launchCategories,
    ...restrictedCategories,
    ...prohibitedCategories,
  ];

  await prisma.category.updateMany({
    where: {
      slug: { notIn: policyCategories.map((category) => category.slug) },
    },
    data: {
      isActive: false,
      isAllowedForListings: false,
      listingPolicy: CategoryListingPolicy.RESTRICTED,
      safetyNotice:
        'Категория требует отдельной проверки перед публикацией.',
    },
  });

  for (const category of launchCategories) {
    await prisma.category.upsert({
      where: { slug: category.slug },
      update: {
        ...category,
        isActive: true,
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
      create: {
        ...category,
        isActive: true,
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
    });
  }

  for (const category of restrictedCategories) {
    await prisma.category.upsert({
      where: { slug: category.slug },
      update: {
        ...category,
        isActive: false,
        isAllowedForListings: false,
        listingPolicy: CategoryListingPolicy.RESTRICTED,
      },
      create: {
        ...category,
        isActive: false,
        isAllowedForListings: false,
        listingPolicy: CategoryListingPolicy.RESTRICTED,
      },
    });
  }

  for (const category of prohibitedCategories) {
    await prisma.category.upsert({
      where: { slug: category.slug },
      update: {
        ...category,
        isActive: false,
        isAllowedForListings: false,
        listingPolicy: CategoryListingPolicy.PROHIBITED,
      },
      create: {
        ...category,
        isActive: false,
        isAllowedForListings: false,
        listingPolicy: CategoryListingPolicy.PROHIBITED,
      },
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
