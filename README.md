# Соседи

Мобильный P2P-сервис платной аренды разрешённых личных вещей между соседями в
России.

MVP соединяет пользователей, которые берут вещи в аренду, и пользователей,
которые сдают свои вещи. Одна вещь в объявлении, дневная ставка в RUB и личная
передача — единственный product flow до первых клиентов. Продажа, дарение,
обмен, услуги, корзина и собственная доставка не входят в MVP.

Продуктовая граница принята в
[ADR-0001](docs/adr/0001-paid-neighbor-item-rental.md), а delivery handoff
исключён из MVP 1.0 в
[ADR-0004](docs/adr/0004-delivery-out-of-mvp-1.md). Backend использует
единый нейтральный `Item`-контракт по `/api/v1/items`; пользователь с ролью
`USER` может и брать чужие вещи, и публиковать свои.

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
operator/             Закрытый React/Vite UI операторов
public-web/           Статический Astro-сайт документов и поддержки
docs/                 Проектная документация
docs/adr/README.md     ADR-правила и шаблон внешних/business решений
docs/testing.md       Команды, test-инфраструктура и coverage baseline
docs/workflow-state-machines.md
                      Канонические FSM-контракты
docs/observability-data-redaction.md
                      Контракт очистки логов и GlitchTip events
docs/data-retention-and-export.md
                      Экспорт, сроки хранения, удаление и legal hold по категориям
docs/production-secrets-runbook.md
                      Выдача, ротация, отзыв и least privilege секретов
docs/production-operations-runbook.md
                      Production inventory и deploy/incident/rollback
docs/postgresql-backups.md
                      Encrypted dual-provider PostgreSQL backup job и smoke gate
docs/s3-backup-and-configuration.md
                      S3 versioning/independent backup и config/signing recovery
docs/recovery-objectives.md
                      RPO/RTO и guarded PostgreSQL + S3 restore drill
docs/security-scanning.md
                      Offline dependency scan и локальный secret scan
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
- объявления доступны только по `/api/v1/items`; legacy `/tools` не
  поддерживается;
- входящие данные валидируются через DTO, `class-validator` и `class-transformer`;
- ответы API используют единый формат `success/data/error`;
- авторизация через SMS OTP, JWT access token и refresh token;
- OTP request требует стабильный `X-Installation-Id` UUID v4 и ограничивается
  отдельно по телефону, installation и прямому socket IP; IP-порог выше
  device-порога, чтобы не блокировать общий NAT слишком рано;
- client IP берётся из `X-Forwarded-For` только когда непосредственный proxy
  входит в точный `TRUSTED_PROXY_IPS`; пустое значение не доверяет ни одному
  proxy, а wildcard и `/0` запрещены;
- production API принимает browser-запросы только из точного
  `CORS_ALLOWED_ORIGINS` и требует HTTPS; reverse proxy обязан передавать
  `X-Forwarded-Proto`, а его IP должен входить в `TRUSTED_PROXY_IPS`;
- `helmet` выставляет базовые security headers, JSON/form body ограничен
  `HTTP_BODY_LIMIT`, а request/header/keep-alive timeout задаются явными env;
- mobile передаёт версии приложения/API; `MIN_SUPPORTED_MOBILE_VERSION`
  повышается только при реальной несовместимости, а `ANDROID_UPDATE_URL` и
  `IOS_UPDATE_URL` задают безопасное действие обновления для своей платформы;
- Swagger UI/OpenAPI доступны локально, но не регистрируются при
  `NODE_ENV=production`; неизвестные ошибки не раскрывают клиенту message/stack;
- все Nest logs проходят через общий sanitizer; raw токены, OTP, cookies,
  телефоны, адреса, KYC/payment payload и presigned URL запрещены;
- refresh token, OTP и очереди хранятся в Redis;
- блокировка и удаление увеличивают серверный `sessionVersion`, поэтому все старые
  access/refresh/admin-токены сразу и навсегда становятся недействительными;
- подтверждённый `DELETE /users/me` сразу закрывает аккаунт, скрывает его
  объявления и отзывает все сессии; при нетерминальной аренде, открытом споре или
  связанной Payment/KYC записи PII сохраняются до завершения обязательств, после
  чего фоновый finalizer выполняет anonymization;
- admin API принимает только отдельную короткую opaque Redis-backed сессию в
  `HttpOnly + Secure + SameSite=Strict` cookie после TOTP или одноразового
  recovery code; обычный access JWT и повторный SMS OTP недостаточны, а
  state-changing запросы требуют CSRF token;
- роль `ADMIN` не выдаёт доступ сама по себе: маршруты требуют отдельные
  `MODERATION`/`SUPPORT` capabilities; `KYC_REVIEW` и `FINANCE` зарезервированы
  для gated KYC/финансовых endpoint;
- публичного admin bootstrap/self-promotion и default credentials нет; первого
  администратора создают только
  [контролируемой operational-процедурой](docs/first-admin-bootstrap.md);
- секреты хранятся только в env.

Создание объявления принимает общие для любой разрешённой вещи поля состояния,
комплектации и условий личной передачи. Публикация возможна только в активной
категории launch whitelist; созданная администратором категория по умолчанию не
получает это разрешение. Статусы `ALLOWED`/`RESTRICTED`/`PROHIBITED`,
обязательные предупреждения и консервативный launch-перечень зафиксированы в
[ADR-0003](docs/adr/0003-launch-category-safety-policy.md); restricted и
prohibited категории backend отклоняет при создании и смене категории.

Документация по схеме БД: [docs/database-schema.md](docs/database-schema.md).
FSM-контракты: [docs/workflow-state-machines.md](docs/workflow-state-machines.md).
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

Mobile Auth использует `--dart-define=API_BASE_URL=...`; в local/debug без
значения Android emulator ходит на `http://10.0.2.2:3000/api/v1`, остальные
платформы — на `http://localhost:3000/api/v1`. Release runtime требует
`APP_ENVIRONMENT=production` и public HTTPS API с точным `/api/v1`.

GlitchTip включается только через `--dart-define=GLITCHTIP_DSN=...`: разрешён
self-hosted HTTPS DSN, hosted `sentry.io` блокируется. `beforeSend` удаляет
user/request/attachments и очищает всё событие. Полный контракт:
[docs/observability-data-redaction.md](docs/observability-data-redaction.md).

В local/debug по умолчанию доступны две явно помеченные UX-заглушки: демо-карта
строится только из публичных приблизительных точек текущего каталога, а карточка
подтверждённой брони арендатора позволяет показать успешную или отклонённую
тестовую оплату без списания денег и без изменения server state. Они всегда
выключены при `APP_ENVIRONMENT=production` и в release; локально их также можно
скрыть через `--dart-define=ENABLE_DEMO_STUBS=false`. Заглушки не закрывают
MapKit, payment/provider, legal и device-smoke gates checklist.

Mobile analytics использует consent-first allowlist из восьми funnel events без
произвольных параметров. AppMetrica transport не подключён и не может собирать
данные до privacy/legal gate; opt-out прекращает отправку и очищает локальное
состояние transport. Контракт: [docs/analytics-funnel.md](docs/analytics-funnel.md).

## Локальный запуск

Команды запускаются из корня проекта.

```bash
make infra-up
make backend-dev
```

PostGIS и Redis зафиксированы по version + digest; порядок безопасного обновления
описан в [docs/container-images.md](docs/container-images.md).
CI cache boundaries для npm, pub, Prisma и CocoaPods описаны в
[docs/build-artifact-cache.md](docs/build-artifact-cache.md).

Проверки:

```bash
make backend-lint
make backend-test
make operator-build
make public-web-check
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

Публичные ответы объявлений не содержат pickup-адрес, точные координаты,
`distanceMeters` или URL оригинала фото. API возвращает модерируемый район,
distance bucket и стабильную coarse-cell; точные данные остаются в приватном
owner/admin-контракте, а participant-доступ будет добавлен вместе с Booking.

Буквальный запрет любой трансграничной передачи несовместим с FCM и Yandex
MapKit. Перед релизом граница `RF only`, согласия и состав передаваемых данных
должны пройти юридическую проверку.

## Публичные и юридические страницы

Локальный черновик Astro-сайта находится в `public-web/`: в нём есть versioned
оферта, rental rules, privacy/consent, политика запрещённых категорий, support и
инструкция закрытия аккаунта. Страницы статические, без авторизации, форм,
пользовательских данных и analytics; каждая версия документа имеет отдельный
неизменяемый URL.

Черновик намеренно закрыт от индексации и не является опубликованной офертой.
Публичный support-канал утверждён: `sosedi.rs@yandex.ru`. Перед использованием
URL в mobile/store listing нужно утвердить юридические тексты, настроить
production-домен/HTTPS и выполнить release smoke.

Пока legal/safety gate и эти URL не готовы, публичные booking/payment функции
считаются выключенными.

## Обязательные проверки до интеграций

- До Payments согласовать с ЮKassa «Безопасную сделку». Если она недоступна,
  MVP бронирует вещь, оплата происходит при передаче, а комиссия Sosedi
  равна 0%.
- До публичной аренды согласовать роль площадки, оферту/rental rules, комиссию,
  отмены/ущерб, eligibility и launch whitelist запрещённых/опасных категорий
  вещей.
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
  с владельцем вещи.

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
