# Sosedi — Master Codex Prompt

> **Архивный документ. Не использовать как источник текущих требований.**
>
> **Раньше:** проект назывался ROSA, mobile планировался на React Native, FCM был
> единственным push-каналом, Sentry не разделялся на SDK и hosted SaaS, а
> платежи ограничивались checkout + webhook без выплат владельцу.
>
> **Теперь (25.07.2026):** актуальный проект Sosedi использует Flutter; текущие
> решения зафиксированы в [AGENTS.md](AGENTS.md),
> [MVP_CHECKLIST.md](MVP_CHECKLIST.md) и
> [sosedi-roadmap.html](sosedi-roadmap.html). Для push используются
> `PushProvider`, FCM, RuStore Push и in-app inbox; ошибки принимает GlitchTip
> self-hosted в РФ; перед production-платежами выбирается «Безопасная сделка»
> ЮKassa либо оплата при передаче.
>
> **Почему документ сохранен:** он объясняет происхождение ранних решений и
> модели данных. Его содержимое ниже является историческим и не должно
> переопределять `AGENTS.md`.

## Контекст проекта

**ROSA** — мобильный P2P-маркетплейс аренды строительного инструмента для физических лиц, мастеров и небольших бригад в России. Платформа соединяет арендаторов (ищут инструмент) и арендодателей (сдают собственный инструмент).

**Разработчик:** один человек + AI-инструменты (Codex, Claude, Cursor).
**Принцип:** минимальная сложность, максимальная рабочесть. Никакой преждевременной архитектуры.

---

## Технологический стек

### Mobile
- **React Native** (Bare Workflow, без Expo)
- TypeScript 5.x
- React Navigation v6
- Yandex MapKit (нативный модуль)
- FCM (Firebase Cloud Messaging) только для push-уведомлений
- React Query (TanStack Query v5)
- Zustand (глобальный стейт)
- React Hook Form + Zod (формы и валидация)

### Backend
- **NestJS** (monolith, без микросервисов)
- TypeScript 5.x
- **Prisma ORM** (НЕ TypeORM — Prisma предпочтительнее для AI-разработки)
- REST API + Swagger/OpenAPI
- JWT (access 15m + refresh 30d) + OTP SMS авторизация
- BullMQ (очереди: обработка фото, SMS)
- WebSocket Gateway (NestJS Gateway) для real-time событий в активном сеансе

### База данных
- **PostgreSQL 15+** с расширением **PostGIS**
- Размещение: только территория РФ (Selectel / Timeweb Cloud / Yandex Cloud)
- Миграции через Prisma Migrate

### Кэш
- **Redis** — OTP-коды, refresh tokens, очереди BullMQ
- Размещение: только территория РФ

### Файловое хранилище
- S3-совместимое (Selectel Object Storage, Yandex Object Storage, VK Cloud)
- Загрузка через presigned URL (клиент → S3 напрямую)
- Обработка через очередь: sharp (thumbnail 200×200, preview 800×600)

### Платежи
- **ЮKassa** (только базовый флоу в MVP: checkout + webhook)
- Холдирование, split payments, автовыплаты — ЗАПРЕЩЕНО до MVP 1.0

### SMS
- SMS.ru или Exolve

### Карты
- Yandex MapKit (карта, метки, кластеризация, геопоиск)

### Аналитика и мониторинг
- AppMetrica (мобильная аналитика, НЕ Firebase Analytics)
- Sentry (ошибки backend и mobile)
- Docker + Docker Compose (инфраструктура)

---

## Схема базы данных (Prisma)

```prisma
// schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum UserRole {
  RENTER      // арендатор
  OWNER       // арендодатель
  ADMIN
}

enum KycStatus {
  NONE
  PENDING
  VERIFIED
  REJECTED
}

enum ToolStatus {
  DRAFT
  PENDING_MODERATION
  ACTIVE
  INACTIVE
  DELETED
}

enum BookingStatus {
  PENDING          // ожидает подтверждения арендодателя
  CONFIRMED        // подтверждено, ожидает оплаты
  PAID             // оплачено
  ACTIVE           // инструмент передан
  RETURNED         // инструмент возвращён
  CANCELLED        // отменено
  DISPUTED         // в споре
  COMPLETED        // завершено (деньги выплачены арендодателю)
}

enum PaymentStatus {
  PENDING
  SUCCEEDED
  FAILED
  REFUNDED
}

enum DisputeStatus {
  OPEN
  IN_REVIEW
  RESOLVED
  CLOSED
}

model User {
  id          String    @id @default(uuid())
  phone       String    @unique
  name        String?
  avatarUrl   String?
  role        UserRole  @default(RENTER)
  kycStatus   KycStatus @default(NONE)
  isBlocked   Boolean   @default(false)
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt

  // relations
  tools          Tool[]
  bookingsAsRenter Booking[] @relation("RenterBookings")
  bookingsAsOwner  Booking[] @relation("OwnerBookings")
  payments       Payment[]
  disputes       Dispute[]
  kycDocuments   KycDocument[]
  auditLogs      AuditLog[]
  supportTickets SupportTicket[]

  @@index([phone])
  @@map("users")
}

model Category {
  id       String @id @default(uuid())
  name     String @unique
  slug     String @unique
  iconUrl  String?
  parentId String?
  parent   Category? @relation("CategoryTree", fields: [parentId], references: [id])
  children Category[] @relation("CategoryTree")
  tools    Tool[]

  @@map("categories")
}

model Tool {
  id            String     @id @default(uuid())
  ownerId       String
  owner         User       @relation(fields: [ownerId], references: [id])
  categoryId    String
  category      Category   @relation(fields: [categoryId], references: [id])
  title         String
  description   String
  pricePerDay   Decimal    @db.Decimal(10, 2)
  deposit       Decimal?   @db.Decimal(10, 2)
  status        ToolStatus @default(DRAFT)
  
  // геолокация: lat/lon хранятся отдельно для Prisma,
  // PostGIS point — через raw SQL / extension
  latitude      Float
  longitude     Float
  address       String
  
  // мета
  brand         String?
  year          Int?
  condition     String?    // new / good / used
  
  createdAt     DateTime   @default(now())
  updatedAt     DateTime   @updatedAt
  
  photos        ToolPhoto[]
  bookings      Booking[]
  availability  ToolAvailability[]

  @@index([ownerId])
  @@index([status])
  @@index([categoryId])
  // Примечание: GIST-индекс на геолокацию создаётся отдельной миграцией:
  // CREATE INDEX idx_tools_location ON tools USING GIST(ST_MakePoint(longitude, latitude)::geography);
  @@map("tools")
}

model ToolPhoto {
  id         String  @id @default(uuid())
  toolId     String
  tool       Tool    @relation(fields: [toolId], references: [id], onDelete: Cascade)
  url        String  // S3 URL оригинал
  thumbUrl   String? // S3 URL thumbnail
  previewUrl String? // S3 URL preview
  order      Int     @default(0)
  isCover    Boolean @default(false)
  createdAt  DateTime @default(now())

  @@index([toolId])
  @@map("tool_photos")
}

model ToolAvailability {
  id        String   @id @default(uuid())
  toolId    String
  tool      Tool     @relation(fields: [toolId], references: [id], onDelete: Cascade)
  date      DateTime @db.Date
  available Boolean  @default(true)

  @@unique([toolId, date])
  @@index([toolId])
  @@map("tool_availability")
}

model Booking {
  id          String        @id @default(uuid())
  toolId      String
  tool        Tool          @relation(fields: [toolId], references: [id])
  renterId    String
  renter      User          @relation("RenterBookings", fields: [renterId], references: [id])
  ownerId     String
  owner       User          @relation("OwnerBookings", fields: [ownerId], references: [id])
  
  startDate   DateTime      @db.Date
  endDate     DateTime      @db.Date
  totalPrice  Decimal       @db.Decimal(10, 2)
  
  status      BookingStatus @default(PENDING)
  
  // фото передачи
  checkoutPhotos String[] // URLs фото при передаче
  returnPhotos   String[] // URLs фото при возврате
  
  createdAt   DateTime      @default(now())
  updatedAt   DateTime      @updatedAt
  
  payment     Payment?
  dispute     Dispute?

  @@index([toolId])
  @@index([renterId])
  @@index([ownerId])
  @@index([status])
  @@map("bookings")
}

model Payment {
  id              String        @id @default(uuid())
  bookingId       String        @unique
  booking         Booking       @relation(fields: [bookingId], references: [id])
  userId          String
  user            User          @relation(fields: [userId], references: [id])
  amount          Decimal       @db.Decimal(10, 2)
  status          PaymentStatus @default(PENDING)
  yookassaPaymentId String?     @unique
  yookassaData    Json?         // raw webhook payload
  createdAt       DateTime      @default(now())
  updatedAt       DateTime      @updatedAt

  @@map("payments")
}

model KycDocument {
  id         String    @id @default(uuid())
  userId     String
  user       User      @relation(fields: [userId], references: [id])
  docType    String    // passport / snils / selfie
  fileUrl    String    // S3 URL (private bucket!)
  status     KycStatus @default(PENDING)
  reviewNote String?
  reviewedAt DateTime?
  createdAt  DateTime  @default(now())

  @@index([userId])
  @@map("kyc_documents")
}

model Dispute {
  id          String        @id @default(uuid())
  bookingId   String        @unique
  booking     Booking       @relation(fields: [bookingId], references: [id])
  initiatorId String
  initiator   User          @relation(fields: [initiatorId], references: [id])
  reason      String
  description String
  photoUrls   String[]
  status      DisputeStatus @default(OPEN)
  resolution  String?
  resolvedAt  DateTime?
  createdAt   DateTime      @default(now())
  updatedAt   DateTime      @updatedAt

  @@map("disputes")
}

model SupportTicket {
  id          String   @id @default(uuid())
  userId      String
  user        User     @relation(fields: [userId], references: [id])
  subject     String
  description String
  photoUrls   String[]
  status      String   @default("open") // open / in_progress / closed
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  @@index([userId])
  @@map("support_tickets")
}

model AuditLog {
  id         String   @id @default(uuid())
  userId     String?
  user       User?    @relation(fields: [userId], references: [id])
  action     String   // e.g. "USER_BLOCKED", "TOOL_APPROVED", "KYC_VERIFIED"
  entityType String?  // "User" | "Tool" | "Booking" | etc
  entityId   String?
  metadata   Json?
  ipAddress  String?
  createdAt  DateTime @default(now())

  @@index([userId])
  @@index([entityType, entityId])
  @@map("audit_logs")
}
```

---

## Правила разработки для Codex

### ВСЕГДА соблюдай

1. **TypeScript строгий режим** — `strict: true` в tsconfig, никаких `any`, никаких `@ts-ignore` без крайней необходимости.

2. **API версионирование** — все эндпоинты начинаются с `/api/v1/`. В NestJS: `app.enableVersioning({ type: VersioningType.URI })`.

3. **Валидация через Zod/class-validator** — входящие данные всегда валидируются. На backend: `class-validator` + `class-transformer` DTO. На mobile: Zod schema для форм.

4. **Обработка ошибок** — глобальный `ExceptionFilter` в NestJS. Всегда возвращать структурированный ответ `{ success, data, error: { code, message } }`.

5. **Логирование** — использовать NestJS Logger или Pino. Логировать: request/response, ошибки, важные бизнес-события (бронирование создано, оплата прошла).

6. **Транзакции Prisma** — операции, затрагивающие несколько таблиц, всегда оборачивать в `prisma.$transaction([...])`.

7. **Rate limiting** — на эндпоинт `/api/v1/auth/send-otp`: max 3 запроса в 10 минут на phone. Через `@nestjs/throttler` + Redis.

8. **Авторизация** — Guard на все эндпоинты кроме публичных. Роли через `@Roles()` декоратор.

9. **Secrets через env** — никаких хардкода ключей. Все секреты через `ConfigModule` + `.env`.

10. **Комментарии на русском** — в бизнес-логике пиши комментарии на русском для ясности.

### ЗАПРЕЩЕНО в этом проекте (до MVP 1.0)

- Микросервисы, отдельные сервисы — только monolith
- CQRS, Event Sourcing — не нужно
- GraphQL — только REST
- Kafka, RabbitMQ — только BullMQ для очередей
- Elasticsearch — только PostgreSQL FTS (tsvector)
- Kubernetes — только Docker Compose
- ML-рекомендации — только простая сортировка
- Рейтинги и отзывы — отложено на MVP 1.0
- Автоматические выплаты — ручные в MVP
- Сложный антифрод — только базовые ограничения

---

## Структура проекта NestJS

```
apps/api/
├── src/
│   ├── main.ts                   # bootstrap, versioning, swagger
│   ├── app.module.ts
│   ├── config/                   # ConfigModule, env validation
│   ├── prisma/                   # PrismaService, PrismaModule
│   ├── auth/                     # SMS OTP + JWT
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   ├── strategies/           # jwt.strategy.ts
│   │   ├── guards/               # jwt-auth.guard.ts, roles.guard.ts
│   │   └── dto/
│   ├── users/
│   ├── tools/                    # объявления инструментов
│   ├── categories/
│   ├── bookings/
│   ├── payments/                 # ЮKassa интеграция
│   ├── kyc/
│   ├── disputes/
│   ├── support/
│   ├── upload/                   # S3 presigned URLs
│   ├── notifications/            # FCM + WebSocket Gateway
│   ├── admin/                    # Admin panel endpoints
│   └── common/
│       ├── filters/              # GlobalExceptionFilter
│       ├── interceptors/         # LoggingInterceptor, AuditInterceptor
│       ├── decorators/           # @CurrentUser(), @Roles()
│       └── dto/                  # PaginationDto, ResponseDto
```

---

## Структура React Native проекта

```
apps/mobile/
├── src/
│   ├── api/                      # React Query hooks + axios клиент
│   │   ├── client.ts             # axios instance с interceptors
│   │   ├── auth.ts
│   │   ├── tools.ts
│   │   ├── bookings.ts
│   │   └── ...
│   ├── screens/
│   │   ├── auth/                 # Onboarding, PhoneInput, OtpVerify
│   │   ├── map/                  # MapScreen (главный экран)
│   │   ├── catalog/              # CatalogScreen, FiltersScreen
│   │   ├── tool/                 # ToolDetailScreen, CreateToolScreen
│   │   ├── booking/              # BookingFlow, BookingDetail
│   │   ├── profile/              # ProfileScreen, MyTools, MyBookings
│   │   └── admin/                # AdminScreen (только для роли ADMIN)
│   ├── components/               # переиспользуемые компоненты
│   ├── navigation/               # React Navigation stacks/tabs
│   ├── store/                    # Zustand stores
│   ├── hooks/                    # кастомные хуки
│   ├── utils/                    # хелперы
│   └── theme/                    # цвета, типографика, размеры
```

---

## Ключевые бизнес-правила

### Авторизация (SMS OTP)
- Пользователь вводит номер телефона (+7XXXXXXXXXX)
- Сервер генерирует 6-значный OTP, сохраняет в Redis с TTL 10 минут
- Отправляет SMS через SMS.ru / Exolve
- Rate limit: 3 OTP на номер в 10 минут, 5 ошибок → блокировка на 30 минут
- После верификации OTP: выдаётся JWT access (15m) + refresh (30d) токены
- Refresh токен хранится в Redis (для возможности инвалидации)

### Объявление инструмента
- Арендодатель создаёт объявление → статус `DRAFT`
- Загружает 1-10 фотографий (через presigned URL → S3 → BullMQ → sharp обработка)
- Отправляет на модерацию → статус `PENDING_MODERATION`
- Администратор одобряет/отклоняет → `ACTIVE` / `DRAFT`
- Поиск по геолокации: `ST_DWithin(location, ST_MakePoint(:lon, :lat)::geography, :radius_meters)`
- Максимальный радиус поиска: 50 км

### Бронирование (State Machine)
```
PENDING → CONFIRMED (арендодатель подтверждает)
PENDING → CANCELLED (любая сторона или истечение 24ч)
CONFIRMED → PAID (после успешной оплаты ЮKassa)
CONFIRMED → CANCELLED (до оплаты)
PAID → ACTIVE (арендодатель отметил передачу + фото)
ACTIVE → RETURNED (арендатор отметил возврат + фото)
RETURNED → COMPLETED (автоматически через 24ч или вручную)
* → DISPUTED (любая сторона открывает спор)
```

### Оплата (ЮKassa MVP)
- Создание платежа при переходе `CONFIRMED`
- ЮKassa возвращает redirect_url → открываем WebView
- Webhook `/api/v1/payments/webhook` → обновление статуса
- Подпись webhook проверяется через HMAC-SHA256
- **НЕ реализуем**: холдирование залога, сплит-платежи, автовыплаты

### KYC (упрощённый MVP)
- Арендодатель загружает фото паспорта (private S3 bucket) + селфи
- Документы видны только администратору
- Администратор вручную устанавливает статус `VERIFIED` / `REJECTED`
- `VERIFIED` отображается как бейдж на профиле

### Геопоиск
```sql
-- Пример запроса для поиска инструментов в радиусе
SELECT t.*, 
  ST_Distance(
    ST_MakePoint(t.longitude, t.latitude)::geography,
    ST_MakePoint($1, $2)::geography
  ) as distance_meters
FROM tools t
WHERE t.status = 'ACTIVE'
  AND ST_DWithin(
    ST_MakePoint(t.longitude, t.latitude)::geography,
    ST_MakePoint($1, $2)::geography, -- $1=lon, $2=lat
    $3 -- $3=radius_meters (max 50000)
  )
ORDER BY distance_meters
LIMIT 50;
```

### Соответствие 152-ФЗ
- Все персональные данные хранятся только на серверах в РФ
- KYC-документы в отдельном приватном S3 bucket, недоступном публично
- При удалении аккаунта: анонимизация (nullify) персональных данных, сохранение ID для финансовых записей
- Audit log для всех операций с персональными данными
- Согласие на обработку ПД при регистрации

---

## Шаблоны кода для часто используемых паттернов

### NestJS Endpoint (пример: создание объявления)
```typescript
// Всегда использовать этот паттерн для endpoint:
@Post()
@UseGuards(JwtAuthGuard)
@ApiOperation({ summary: 'Создать объявление инструмента' })
@ApiResponse({ status: 201, type: ToolResponseDto })
async createTool(
  @CurrentUser() user: UserPayload,
  @Body() dto: CreateToolDto,
): Promise<ApiResponse<ToolResponseDto>> {
  const tool = await this.toolsService.create(user.sub, dto);
  return { success: true, data: tool };
}
```

### React Query Hook (пример)
```typescript
// Всегда использовать этот паттерн для data fetching:
export function useTools(params: ToolsQueryParams) {
  return useQuery({
    queryKey: ['tools', params],
    queryFn: () => toolsApi.getTools(params),
    staleTime: 5 * 60 * 1000, // 5 минут
  });
}
```

### Обработка ошибок в React Native
```typescript
// Axios interceptor — глобальная обработка:
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // refresh token или logout
    }
    return Promise.reject(error);
  }
);
```

---

## Окружение и переменные

```env
# .env.example
DATABASE_URL="postgresql://user:pass@localhost:5432/rosa_db"
REDIS_URL="redis://localhost:6379"

JWT_ACCESS_SECRET="your_access_secret"
JWT_REFRESH_SECRET="your_refresh_secret"
JWT_ACCESS_EXPIRES_IN="15m"
JWT_REFRESH_EXPIRES_IN="30d"

SMS_PROVIDER="smsru" # smsru | exolve
SMSRU_API_KEY="your_key"

S3_ENDPOINT="https://s3.selcdn.ru"
S3_BUCKET_PUBLIC="rosa-public"
S3_BUCKET_PRIVATE="rosa-kyc-private"
S3_ACCESS_KEY="your_key"
S3_SECRET_KEY="your_secret"

YOOKASSA_SHOP_ID="your_shop_id"
YOOKASSA_SECRET_KEY="your_secret"
YOOKASSA_WEBHOOK_SECRET="your_webhook_secret"

SENTRY_DSN="your_sentry_dsn"

FRONTEND_ADMIN_URL="http://localhost:3001"
```

---

## Приоритет задач (MVP 0.1)

Реализовывай строго в этом порядке:

1. **Database schema** — Prisma schema + начальная миграция + seed с категориями
2. **Auth module** — SMS OTP → JWT, rate limiting, refresh tokens
3. **Users module** — профиль, обновление данных, удаление аккаунта
4. **Categories module** — CRUD (только admin), seed данных
5. **Tools module** — CRUD объявлений, статусы, геопоиск (PostGIS)
6. **Upload module** — presigned S3 URL + BullMQ обработка фото
7. **Admin module** — модерация объявлений, управление пользователями
8. **Mobile: Auth screens** — Onboarding, PhoneInput, OtpVerify
9. **Mobile: Map screen** — Yandex MapKit, маркеры, кластеризация
10. **Mobile: Catalog screen** — список, поиск, фильтры
11. **Mobile: Tool detail** — карточка, фотогалерея
12. **Mobile: Create tool** — форма, фотозагрузка, модерация

---

*Этот промпт является источником истины для всей кодовой базы ROSA. При любом конфликте между требованиями пользователя и этим документом — уточняй.*
