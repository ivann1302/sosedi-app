# Мини-учебник по backend технологиям Sosedi

Источник: код в `backend/`.

Этот документ объясняет не весь backend-стек в вакууме, а то, как технологии уже используются в проекте Sosedi MVP. Главный принцип: понимать рабочий монолит NestJS и быстро добавлять фичи без лишней архитектуры.

## 1. Общая картина

Backend - монолитный REST API на NestJS.

Основной путь запроса:

```text
HTTP request
-> Controller
-> DTO validation
-> Guard, если нужна авторизация
-> Service
-> Prisma / Redis / S3 / BullMQ
-> ok(data)
-> { success, data, error }
```

Ключевые файлы:

| Что | Где |
| --- | --- |
| Точка входа | `backend/src/main.ts` |
| Корневой модуль | `backend/src/app.module.ts` |
| Prisma schema | `backend/prisma/schema.prisma` |
| Первая миграция | `backend/prisma/migrations/20260602000100_init_database_schema/migration.sql` |
| Единый формат ответа | `backend/src/common/http/api-response.ts` |
| Единый формат ошибок | `backend/src/common/filters/http-exception.filter.ts` |
| Auth | `backend/src/auth/` |
| Users | `backend/src/users/` |
| Categories | `backend/src/categories/` |
| Tools | `backend/src/tools/` |
| Upload | `backend/src/upload/` |
| Admin | `backend/src/admin/` |

## 2. NestJS

NestJS дает структуру приложения: модули, контроллеры, сервисы и dependency injection.

В `main.ts` включены базовые правила backend:

```ts
app.setGlobalPrefix('api/v1');
app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
app.useGlobalFilters(new HttpExceptionFilter());
SwaggerModule.setup('api/docs', app, swaggerDocument);
```

Что это значит:

- все endpoint начинаются с `/api/v1`;
- входящие DTO валидируются глобально;
- лишние поля выкидываются через `whitelist`;
- query/body значения могут преобразовываться через `class-transformer`;
- ошибки приводятся к единому формату;
- Swagger доступен на `/api/docs`.

`AppModule` собирает фичи:

```text
AuthModule
UsersModule
CategoriesModule
ToolsModule
UploadModule
AdminModule
```

Правило для MVP: новая крупная область получает простой модуль `feature.module.ts`, контроллер, сервис и DTO. Не нужны repository pattern, factories и лишние слои.

## 3. REST controllers

Controller принимает HTTP-запрос и почти не содержит бизнес-логики.

Пример из `ToolsController`:

```ts
@Get()
async list(@Query() query: ListToolsQueryDto) {
  return ok(await this.tools.listPublic(query));
}
```

Хороший controller:

- читает `@Body`, `@Query`, `@Param`, `@CurrentUser`;
- вызывает один метод service;
- возвращает `ok(result)`;
- не работает напрямую с Prisma, Redis или S3.

## 4. DTO, class-validator и class-transformer

DTO описывает входные данные endpoint.

В проекте используются:

- `class-validator` - проверка типа, длины, диапазона, enum, uuid;
- `class-transformer` - преобразование строк из query/body в нужный тип.

Пример из `CreateToolDto`:

```ts
@Transform(numberFromInput)
@IsNumber({ maxDecimalPlaces: 2 })
@Min(1)
@Max(1_000_000)
pricePerDay: number;
```

Почему это важно:

- mobile может прислать числа строками;
- backend приводит их к `number`;
- невалидные данные не доходят до service;
- service проверяет только бизнес-правила.

Примеры бизнес-правил, которые оставлены в service:

- `minPrice` не может быть больше `maxPrice`;
- координаты должны приходить парой;
- радиус геопоиска не больше 50 км;
- `availableFrom` не может быть позже `availableTo`;
- фото можно загрузить только к своему объявлению.

## 5. Единый формат ответа

Успешный ответ строится через `ok(data)`:

```json
{
  "success": true,
  "data": {},
  "error": null
}
```

Ошибка строится через `HttpExceptionFilter`:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Описание ошибки"
  }
}
```

Практическое правило: в controller не собирать JSON руками. Возвращать `ok(...)`, а ошибки кидать через Nest exceptions: `BadRequestException`, `UnauthorizedException`, `ForbiddenException`, `NotFoundException`, `ConflictException`.

## 6. Auth: OTP, Redis, JWT

Авторизация построена вокруг телефона и SMS OTP.

Флоу:

```text
POST /api/v1/auth/otp/request
-> normalize phone
-> rate limit in Redis
-> generate 6-digit OTP
-> bcrypt hash
-> save hash to Redis with TTL
-> send SMS

POST /api/v1/auth/otp/verify
-> normalize phone
-> compare OTP with bcrypt
-> create user if needed
-> issue access + refresh JWT
-> save refresh token jti in Redis
```

Redis ключи из `AuthService`:

| Ключ | Для чего |
| --- | --- |
| `auth:otp:code:{phone}` | bcrypt hash OTP |
| `auth:otp:send:{phone}` | лимит выдачи OTP |
| `auth:otp:fail:{phone}` | счетчик неверных кодов |
| `auth:otp:block:{phone}` | блокировка после ошибок |
| `auth:refresh:{jti}` | активный refresh token |

Текущие лимиты:

- OTP живет 5 минут;
- 3 OTP за 10 минут;
- 5 неверных кодов;
- блокировка на 30 минут;
- access token по умолчанию 15 минут;
- refresh token по умолчанию 30 дней.

Refresh token ротируется: при refresh старый `jti` удаляется из Redis, затем выдается новая пара токенов.

## 7. Guards и роли

`JwtAuthGuard` делает три вещи:

1. достает Bearer token;
2. проверяет access JWT;
3. читает пользователя из БД и кладет `request.user`.

`RolesGuard` проверяет `@Roles(...)`.

Пример:

```ts
@ApiBearerAuth()
@Roles(UserRole.ADMIN)
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('admin')
export class AdminController {}
```

Практическое правило:

- публичные endpoint без guard;
- личные endpoint через `JwtAuthGuard`;
- admin/owner действия через `JwtAuthGuard` + `RolesGuard`.

## 8. Prisma ORM

Prisma используется как основной доступ к PostgreSQL.

`PrismaService` минимальный:

```ts
export class PrismaService extends PrismaClient implements OnModuleDestroy {
  async onModuleDestroy() {
    await this.$disconnect();
  }
}
```

В service обычно используются:

- `findMany`;
- `findFirst`;
- `findUnique`;
- `create`;
- `update`;
- `updateMany`;
- `upsert`;
- `$transaction`;
- `$queryRaw` для PostGIS.

Пример транзакции из создания объявления:

```ts
await this.prisma.$transaction(async (tx) => {
  await tx.user.updateMany({
    where: { id: ownerId, role: UserRole.RENTER },
    data: { role: UserRole.OWNER, kycStatus: KycStatus.PENDING },
  });

  return tx.tool.create({ data, select: toolSelect });
});
```

Почему транзакция нужна: роль пользователя и объявление должны измениться вместе.

## 9. PostgreSQL и PostGIS

Основная база - PostgreSQL. Для геопоиска включен PostGIS.

В Prisma schema поле:

```prisma
location Unsupported("geography(Point,4326)")?
```

Это значит: Prisma знает, что колонка есть, но не умеет работать с ней как с обычным полем. Поэтому геопоиск идет через raw SQL.

Миграция делает:

- `CREATE EXTENSION IF NOT EXISTS postgis`;
- добавляет `tools.location geography(Point, 4326)`;
- создает trigger `tools_update_location`;
- добавляет GiST index `tools_location_idx`.

Координаты хранятся отдельно:

```text
latitude
longitude
location
```

`latitude` и `longitude` удобны для API и Prisma. `location` нужна для быстрых `ST_DWithin` и `ST_Distance`.

Важный порядок координат PostGIS:

```text
ST_MakePoint(longitude, latitude)
```

## 10. Геопоиск инструментов

`ToolsService.listPublic()` работает в двух режимах.

Без координат:

```text
Prisma findMany
-> фильтры
-> сортировка по дате или цене
```

С координатами:

```text
Prisma.$queryRaw
-> ST_DWithin
-> ST_Distance
-> получить id и distanceMeters
-> Prisma findMany по id
-> сохранить порядок raw SQL результата
```

Почему так: Prisma удобна для обычных relation/select, а PostGIS расстояния проще и надежнее считать raw SQL.

Ограничение MVP: радиус поиска до 50 км.

## 11. Redis и ioredis

Redis используется для:

- OTP;
- refresh token storage;
- BullMQ очередей.

`RedisService` создает один клиент `ioredis`:

```ts
new Redis(config.get<string>('REDIS_URL') ?? 'redis://localhost:6379')
```

Для OTP и refresh токенов Redis хорош потому, что:

- есть TTL;
- можно быстро инкрементить счетчики;
- можно отозвать refresh token без изменения БД.

## 12. S3-compatible storage и presigned URL

Backend не принимает файлы через multipart. Вместо этого он выдает presigned URL, а mobile грузит файл напрямую в S3-compatible storage.

Флоу фото инструмента:

```text
POST /api/v1/uploads/presigned-url
-> проверить contentType и sizeBytes
-> проверить владельца tool
-> создать S3 key
-> отдать PUT uploadUrl

Mobile
-> PUT file to uploadUrl

POST /api/v1/uploads/tool-photos/confirm
-> проверить owner
-> проверить key prefix
-> создать ToolPhoto
-> поставить BullMQ job
```

Разрешенные типы:

- `image/jpeg`;
- `image/png`;
- `image/webp`.

Максимальный размер: 10 МБ.

KYC файлы получают URL в приватный bucket. Для них `publicUrl` равен `null`.

## 13. AWS SDK для S3

Используются:

- `@aws-sdk/client-s3`;
- `@aws-sdk/s3-request-presigner`.

`S3StorageService` отвечает за:

- создание presigned PUT URL;
- чтение объекта в `Buffer`;
- загрузку обработанных изображений;
- сборку публичного URL.

Все настройки берутся из env:

```text
S3_ENDPOINT
S3_REGION
S3_ACCESS_KEY
S3_SECRET_KEY
S3_BUCKET_PUBLIC
S3_BUCKET_PRIVATE
S3_PUBLIC_BASE_URL
S3_FORCE_PATH_STYLE
```

Секреты не хранить в коде.

## 14. BullMQ и Sharp

BullMQ используется для фоновой обработки фото.

Почему не синхронно:

- создание объявления и подтверждение загрузки не ждут resize;
- тяжелая работа уходит в worker;
- при ошибке задача может повториться.

Очередь:

```text
photo-processing
```

Job:

```text
tool-photo-uploaded
```

`PhotoProcessingWorker`:

1. скачивает оригинал из S3;
2. делает `thumbnail` 200x200 WebP;
3. делает `preview` 800x600 WebP;
4. загружает варианты в S3;
5. обновляет `thumbnailUrl` и `previewUrl` в `tool_photos`.

`NODE_ENV=test` отключает worker на старте приложения, чтобы тесты не поднимали реальную очередь.

## 15. Swagger / OpenAPI

Swagger подключен в `main.ts`:

```ts
const swaggerConfig = new DocumentBuilder()
  .setTitle('Соседи API')
  .setVersion('1.0')
  .addBearerAuth()
  .build();
```

Адрес:

```text
/api/docs
```

В controller используются:

- `@ApiTags`;
- `@ApiBearerAuth`;
- `@ApiOperation`;
- `@ApiParam`;
- `@ApiProperty` в DTO.

Практическое правило: если меняется endpoint или DTO, нужно обновить Swagger-декораторы там же.

## 16. Jest tests

Backend тестируется через Jest.

Команды:

```bash
make backend-test
make backend-test-e2e
```

В проекте уже есть unit tests для:

- auth;
- users;
- categories;
- tools;
- upload;
- photo processing worker;
- admin.

Что тестировать в первую очередь:

- бизнес-правила;
- state transitions;
- guards и роли;
- валидацию, если она неочевидная;
- багфиксы;
- сервисы, которые меняют данные.

Не нужно писать тесты верстки или snapshot tests для backend.

## 17. Локальная инфраструктура

`docker-compose.yml` поднимает:

- PostgreSQL/PostGIS `postgis/postgis:15-3.5`;
- Redis `redis:7` в текущем локальном окружении.

> **Изменение решения от 25.07.2026**
>
> **Раньше:** изменяемый тег `redis:7` считался достаточным и для дальнейшего
> развертывания.
>
> **Теперь:** перед production нужно выбрать лицензионно подходящую конкретную
> версию Redis либо совместимую версию Valkey, проверить BullMQ
> integration-тестом и зафиксировать image digest в private OCI registry РФ.
>
> **Почему:** изменяемый тег не гарантирует повторяемую версию и может незаметно
> привести к другой лицензии или артефакту из внешнего registry.

Команды из корня проекта:

```bash
make infra-up
make backend-dev
make backend-build
make backend-lint
make backend-test
make backend-test-e2e
make backend-prisma-generate
make backend-prisma-migrate
```

## 18. Env переменные backend

Минимальный набор для текущего backend:

```text
PORT
DATABASE_URL
REDIS_URL
JWT_ACCESS_SECRET
JWT_REFRESH_SECRET
JWT_ACCESS_EXPIRES_IN
JWT_REFRESH_EXPIRES_IN
S3_ENDPOINT
S3_REGION
S3_ACCESS_KEY
S3_SECRET_KEY
S3_BUCKET_PUBLIC
S3_BUCKET_PRIVATE
S3_PUBLIC_BASE_URL
S3_FORCE_PATH_STYLE
NODE_ENV
```

Значения секретов должны приходить только из env.

## 19. Как добавлять новую backend фичу

Простой порядок:

1. Проверить, нужна ли фича для MVP.
2. Если нужна БД - изменить `schema.prisma`.
3. Создать migration через `make backend-prisma-migrate`.
4. Создать feature module, controller, service, DTO.
5. Подключить module в `AppModule`.
6. Добавить guards, если endpoint не публичный.
7. Вернуть ответы через `ok(...)`.
8. Использовать Prisma transaction, если меняется несколько сущностей.
9. Добавить тесты там, где есть логика или риск регрессии.
10. Запустить релевантные проверки.

Минимальная структура:

```text
backend/src/booking/
booking.module.ts
booking.controller.ts
booking.service.ts
dto/
```

Не добавлять extra layers без причины.

## 20. Антипаттерны для этого MVP

Не использовать до MVP 1.0:

- microservices;
- CQRS;
- event sourcing;
- DDD;
- GraphQL;
- Kafka/RabbitMQ;
- repository pattern;
- service factories;
- generic factories;
- clean architecture;
- feature flags.

Если можно сделать через controller + DTO + service + Prisma, так и делать.

## 21. Короткая шпаргалка

| Задача | Технология |
| --- | --- |
| REST API | NestJS controllers |
| Бизнес-логика | NestJS services |
| Валидация входа | DTO + class-validator |
| Преобразование input | class-transformer |
| Документация API | Swagger/OpenAPI |
| Авторизация | JWT + guards |
| OTP и refresh state | Redis |
| База | PostgreSQL |
| ORM | Prisma |
| Геопоиск | PostGIS + raw SQL |
| Файлы | S3-compatible storage |
| Прямая загрузка | Presigned URL |
| Обработка фото | BullMQ + Sharp |
| Тесты | Jest |
