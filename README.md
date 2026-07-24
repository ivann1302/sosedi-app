# Соседи

Мобильный P2P-маркетплейс аренды строительного инструмента для России.

MVP соединяет арендаторов, которые ищут инструмент, и владельцев, которые сдают свой инструмент в аренду. Главный фокус проекта: быстро получить рабочий продукт без лишней архитектуры.

## Статус MVP

Источник прогресса: [MVP_CHECKLIST.md](MVP_CHECKLIST.md).

Текущий порядок разработки:

1. Database schema
2. Auth
3. Users
4. Categories
5. Tools
6. Upload
7. Admin
8. Mobile Auth
9. Mobile Map
10. Mobile Catalog
11. Tool Details
12. Create Tool
13. Booking
14. Payments
15. KYC
16. Support
17. Notifications

После закрытия пунктов чеклиста нужно обновлять эту документацию, если изменились поведение продукта, структура проекта, команды запуска, env-переменные, схема данных или API.

## Стек

Подробный список технологий: [TECHNOLOGIES.md](TECHNOLOGIES.md).

Коротко:

- Mobile: Flutter, Dart, GoRouter, Riverpod, Dio, Freezed, Json Serializable.
- Backend: NestJS monolith, TypeScript, Prisma, REST API, JWT, Swagger.
- Database: PostgreSQL 15+, PostGIS.
- Cache and queues: Redis, BullMQ.
- Storage: S3-compatible storage через presigned URL.
- Payments: ЮKassa checkout и webhook.
- Observability: Sentry, AppMetrica.

## Структура

```text
backend/              NestJS REST API
mobile/               Flutter приложение
docs/                 Проектная документация
MVP_CHECKLIST.md      Порядок реализации MVP
TECHNOLOGIES.md       Технологический стек
docker-compose.yml    Локальная инфраструктура
Makefile              Единые команды разработки
```

Backend остается монолитом. До MVP 1.0 не используются microservices, CQRS, GraphQL, Kafka, Kubernetes, Elasticsearch и другие сложные паттерны без прямой необходимости.

## Backend

Backend реализуется на NestJS, Prisma и PostgreSQL/PostGIS.

Основные правила:

- все API endpoints начинаются с `/api/v1/`;
- входящие данные валидируются через DTO, `class-validator` и `class-transformer`;
- ответы API используют единый формат `success/data/error`;
- авторизация через SMS OTP, JWT access token и refresh token;
- refresh token, OTP и очереди хранятся в Redis;
- секреты хранятся только в env.

Документация по схеме БД: [docs/database-schema.md](docs/database-schema.md).

## Mobile

Mobile реализуется на Flutter с feature based architecture.

Базовая структура:

```text
lib/
core/
features/
shared/
main.dart
```

Основной поток зависимостей:

```text
UI -> Provider -> Service -> API
```

Используются Riverpod, GoRouter, Dio, Freezed и Json Serializable. Бизнес-логику не нужно держать внутри Widget.

Mobile Auth использует `--dart-define=API_BASE_URL=...`; если значение не передано, Android emulator ходит на `http://10.0.2.2:3000/api/v1`, остальные платформы — на `http://localhost:3000/api/v1`.

## Локальный запуск

Команды запускаются из корня проекта.

```bash
make infra-up
make backend-dev
```

Проверки:

```bash
make backend-lint
make backend-test
make mobile-analyze
make mobile-test
make check
```

Генерация:

```bash
make backend-prisma-generate
make backend-prisma-migrate
make mobile-gen
```

## Данные и РФ

Персональные данные должны храниться на территории РФ.

Важно:

- не использовать Firebase Auth, AWS Cognito, Supabase Auth;
- KYC-документы хранить только в приватном S3 bucket;
- для админских действий вести аудит;
- не хранить секреты и ключи в коде.

## Обновление документации

Документацию нужно обновлять в той же задаче, где закрывается пункт из [MVP_CHECKLIST.md](MVP_CHECKLIST.md).

Обновлять нужно:

- [README.md](README.md), если изменились общие правила, запуск, структура или поведение MVP;
- [TECHNOLOGIES.md](TECHNOLOGIES.md), если добавлена, удалена или заменена технология;
- `docs/*`, если изменилась схема данных, API, бизнес-правила или важные процессы;
- Swagger/OpenAPI, если изменились backend endpoints или DTO.

Перед заменой `[ ]` на `[x]` в чеклисте нужно проверить, нужна ли правка документации.
