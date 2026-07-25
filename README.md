# Соседи

Мобильный P2P-маркетплейс аренды строительного инструмента для России.

MVP соединяет арендаторов, которые ищут инструмент, и владельцев, которые сдают свой инструмент в аренду. Главный фокус проекта: быстро получить рабочий продукт без лишней архитектуры.

## Статус MVP

Единственный исполняемый источник scope, порядка, Definition of Done и прогресса:
[MVP_CHECKLIST.md](MVP_CHECKLIST.md). `sosedi-roadmap.html` является его
визуальным представлением, [ADR](docs/adr/README.md) фиксируют принятые
business/legal/provider-решения, а локальный игнорируемый `AGENTS.md` не может
менять roadmap.

Актуальная последовательность включает P0 security/privacy, product и mobile
функции, отдельные Booking/Payment/Payout/Dispute state machine, marketplace/
payment/KYC legal gates и обязательный production-readiness этап. Не дублируем
полный нумерованный список здесь, чтобы он не расходился с checklist.

После закрытия пунктов чеклиста нужно обновлять эту документацию, если изменились поведение продукта, структура проекта, команды запуска, env-переменные, схема данных или API.

## Стек

Подробный список технологий: [TECHNOLOGIES.md](TECHNOLOGIES.md).

Коротко:

- Mobile: Flutter, Dart, GoRouter, Riverpod, Dio, Freezed, Json Serializable.
- Backend: NestJS monolith, TypeScript, Prisma, REST API, JWT, Swagger.
- Operator web: React, Vite, TypeScript.
- Public legal/support web: Astro, TypeScript, без авторизации и ПД.
- Database: PostgreSQL 15+, PostGIS.
- Cache and queues: Redis, BullMQ.
- Storage: один основной S3-compatible провайдер в РФ через presigned URL.
- Payments: комиссия только через согласованную ЮKassa «Безопасную сделку»;
  оплата при передаче — временный pilot с комиссией Sosedi 0%.
- Notifications: FCM, RuStore Push и in-app inbox через единый `PushProvider`.
- Observability: `sentry_flutter` SDK с GlitchTip self-hosted в РФ и AppMetrica.

## Структура

```text
backend/              NestJS REST API
mobile/               Flutter приложение
docs/                 Проектная документация
docs/adr/README.md     ADR-правила и шаблон внешних/business решений
docs/testing.md       Команды, test-инфраструктура и coverage baseline
MVP_CHECKLIST.md      Порядок реализации MVP
TECHNOLOGIES.md       Технологический стек
DEVELOPMENT_BEST_PRACTICES.md
                      Стандарт разработки и Definition of Done
docker-compose.yml    Локальная инфраструктура
Makefile              Единые команды разработки
```

Backend остается монолитом. До MVP 1.0 не используются microservices, CQRS, GraphQL, Kafka, Kubernetes, Elasticsearch и другие сложные паттерны без прямой необходимости.

Практические правила реализации, безопасности, тестирования и эксплуатации:
[DEVELOPMENT_BEST_PRACTICES.md](DEVELOPMENT_BEST_PRACTICES.md).

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
Стратегия и команды тестирования: [docs/testing.md](docs/testing.md).

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

Полный CI-контур с coverage, отдельными PostGIS/Redis и backend e2e:

```bash
make ci
make test-infra-down
```

Генерация:

```bash
make backend-prisma-generate
make backend-prisma-migrate
make mobile-gen
```

## Данные и РФ

Основная БД, телефоны, профили, адреса, фотографии, платежные записи и резервные
копии должны храниться на территории РФ. KYC-документы входят в этот перечень
только если ADR выбрал ветку `LOCAL_KYC`; при `PROVIDER_MANAGED` Sosedi их не
собирает.

Важно:

- не использовать Firebase Auth, AWS Cognito, Supabase Auth;
- сначала предпочитать provider-managed identification; KYC-документы в Sosedi
  собирать только после legal gate и хранить в приватном S3 bucket;
- для админских действий вести аудит;
- передавать внешним SDK только минимальные технические идентификаторы при
  наличии документированного правового основания;
- не помещать персональные данные, JWT и детали заказа в push payload,
  аналитику и отчеты об ошибках;
- не хранить секреты и ключи в коде.

Буквальный запрет любой трансграничной передачи несовместим с FCM и Yandex
MapKit. Перед релизом граница `RF only`, согласия и состав передаваемых данных
должны пройти юридическую проверку.

## Обязательные проверки до интеграций

- До Payments согласовать с ЮKassa «Безопасную сделку». Если она недоступна,
  MVP бронирует инструмент, оплата происходит при передаче, а комиссия Sosedi
  равна 0%.
- До публичной аренды согласовать роль площадки, оферту/rental rules, комиссию,
  отмены/ущерб, eligibility и запрещённые/опасные категории инструмента.
- До KYC определить правовое основание, согласия, сроки хранения и удаления,
  доступ администраторов и аудит. До этого не собирать паспорт и селфи.
- Заранее проверить Apple Developer, Google Play Console и RuStore: регистрацию,
  оплату/продление, signing keys и тестовую публикацию.
- Выбрать одного основного S3-провайдера для MVP: Selectel или Yandex Object
  Storage. SMS.ru использовать как основной SMS-сервис, Exolve оставить
  документированным резервом.
- Хранить lock-файлы, фиксировать production-образы по версии и digest,
  настроить российский/private registry и кеш npm, pub, Prisma и CocoaPods.

## История решений — 25.07.2026

### Платежи

- **Раньше:** только ЮKassa checkout и webhook, без hold, split и автоматических
  выплат.
- **Теперь:** monetized MVP разрешён только через согласованную с ЮKassa
  «Безопасную сделку»; оплата при передаче — pilot с комиссией Sosedi 0%.
- **Почему:** checkout-only принимает деньги, но не завершает расчеты P2P-сделки
  с владельцем инструмента.

### Уведомления

- **Раньше:** единственным push-каналом был FCM.
- **Теперь:** минимальный `PushProvider` использует FCM и RuStore Push, на iOS —
  APNs через FCM или напрямую; in-app inbox остается источником истины. Push
  содержит только непрозрачный `eventId`.
- **Почему:** FCM не покрывает Android без Google Mobile Services, а персональные
  данные нельзя помещать во внешний push payload.

### Мониторинг ошибок

- **Раньше:** технология была указана как Sentry без уточнения размещения.
- **Теперь:** `sentry_flutter` используется только как клиентский SDK и отправляет
  очищенные события в GlitchTip self-hosted на VPS в РФ; hosted `sentry.io` не
  используется.
- **Почему:** внешний SaaS не соответствует требованиям проекта по доступности и
  месту хранения данных.

### KYC, публикация и поставка зависимостей

- **Раньше:** KYC, публикация в магазинах и внешние registry проверялись на своих
  поздних этапах.
- **Теперь:** юридический KYC gate, store readiness и кеши/зеркала зависимостей
  проверяются до соответствующих интеграций.
- **Почему:** эти риски нельзя надежно устранить только изменениями кода в конце
  разработки.

## Обновление документации

Документацию нужно обновлять в той же задаче, где закрывается пункт из [MVP_CHECKLIST.md](MVP_CHECKLIST.md).

Обновлять нужно:

- [README.md](README.md), если изменились общие правила, запуск, структура или поведение MVP;
- [TECHNOLOGIES.md](TECHNOLOGIES.md), если добавлена, удалена или заменена технология;
- [DEVELOPMENT_BEST_PRACTICES.md](DEVELOPMENT_BEST_PRACTICES.md), если меняется стандарт разработки или Definition of Done;
- `docs/*`, если изменилась схема данных, API, бизнес-правила или важные процессы;
- Swagger/OpenAPI, если изменились backend endpoints или DTO.

Перед заменой `[ ]` на `[x]` в чеклисте нужно проверить, нужна ли правка документации.
