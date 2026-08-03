# Sosedi — стандарт разработки

Актуально на: 24 июля 2026 года.

Этот документ дополняет `AGENTS.md` и переводит его архитектурные ограничения в
практические правила. При конфликте приоритет имеет `AGENTS.md`, затем требования
продукта и только затем этот документ.

Ключевые слова:

- **MUST** — обязательное правило;
- **SHOULD** — правило по умолчанию; отклонение нужно объяснить в PR;
- **MAY** — допустимый вариант, когда он действительно нужен.

## 1. Главные принципы

1. **KISS и YAGNI.** Реализуем ближайший пользовательский сценарий самым простым
   поддерживаемым способом.
2. **Модульный монолит.** До доказанной необходимости не добавляем микросервисы,
   CQRS, GraphQL, Kafka/RabbitMQ, Kubernetes, Elasticsearch, Repository Pattern,
   Clean Architecture, фабрики и feature flags.
3. **Вертикальные изменения.** Одна задача должна включать весь необходимый путь:
   схема данных → API → мобильный клиент → тесты → документация.
4. **Сервер — источник истины.** Клиент не определяет права, цену, итоговый статус
   бронирования или платежа.
5. **Безопасность и приватность по умолчанию.** Телефон, документы KYC, токены,
   координаты и платёжные данные не попадают в логи, аналитику и push-сообщения.
6. **Измеряем до оптимизации.** Индексы, кеширование и архитектурные усложнения
   добавляются после появления запроса, метрики или профиля, подтверждающих проблему.
7. **Один способ сделать типовую операцию.** Общие ответы API, обработка ошибок,
   логирование, авторизация и конфигурация не дублируются по модулям.

## 2. Границы архитектуры

### Backend

Backend остаётся NestJS-монолитом с модулями по предметным областям:

```text
Controller → Service → Prisma / Redis / S3 / внешний API
```

- Controller MUST заниматься HTTP-контрактом: DTO, guards, status code и вызов service.
- Service MUST содержать бизнес-правила и границы транзакций.
- Prisma-запрос MAY находиться в service. Отдельный repository не создаётся только
  ради обёртки над Prisma.
- Интеграции с S3, push-транспортами, YooKassa и другими внешними системами
  SHOULD иметь один небольшой provider на интеграцию.
- Модули не должны импортировать внутренние файлы друг друга в обход публичных
  providers/exports.
- Циклические зависимости нельзя маскировать `forwardRef` без устранения причины.

### Flutter

Мобильное приложение организуется по функциям:

```text
lib/
├── core/
│   ├── config/
│   ├── network/
│   ├── router/
│   ├── storage/
│   └── theme/
└── features/
    ├── auth/
    ├── catalog/
    ├── map/
    ├── item/
    ├── booking/
    └── <feature>/
```

Не нужно заранее создавать внутри feature каталоги `data/domain/presentation` или
другие пустые слои. Для маленькой функции достаточно:

```text
Widget → Riverpod Provider/Notifier → Service/API
```

- Widget MUST только отображать состояние и отправлять пользовательские события.
- Бизнес-правила, сетевые запросы и работа с хранилищем в `build()` запрещены.
- Один provider/notifier SHOULD владеть состоянием одного экрана или сценария.
- Общий код переносится в `core` только после второго реального использования.
- Глубина каталогов SHOULD оставаться не больше четырёх уровней.

## 3. TypeScript и NestJS

### Типы и код

- Новому коду запрещены необоснованные `any`, non-null assertion (`!`) и
  небезопасные приведения `as`.
- Для конечных наборов значений использовать enum/union, а не произвольные строки.
- Входные DTO MUST быть классами с `class-validator`; интерфейс не даёт NestJS
  runtime-метаданных для валидации.
- DTO API не должен быть Prisma-моделью. Возвращаем только явно разрешённые поля.
- Функции SHOULD быть короткими и иметь один уровень ответственности.
- Комментарий объясняет бизнес-причину, а не пересказывает код. Бизнес-комментарии
  пишутся на русском.
- `noImplicitAny`, `strictBindCallApply` и `noFallthroughCasesInSwitch` SHOULD
  включаться поэтапно; новый код не должен увеличивать число исключений.

### HTTP API

- Все маршруты остаются под `/api/v1`.
- Глобальный `ValidationPipe` MUST использовать `transform: true`, `whitelist: true`
  и SHOULD отклонять лишние поля через `forbidNonWhitelisted: true`.
- Для path/query параметров использовать DTO либо явные `ParseUUIDPipe`,
  `ParseIntPipe` и похожие pipes.
- Ответ сохраняет единый контракт:

```json
{
  "success": true,
  "data": {},
  "error": null
}
```

- Ошибка MUST иметь стабильный машинный `code`, безопасное сообщение и
  `requestId`. Stack trace, SQL и детали инфраструктуры клиенту не возвращаются.
- Использовать корректные HTTP-коды: `201` для создания, `204` для удаления без
  тела, `400` для неверного ввода, `401` без аутентификации, `403` без права,
  `404` для отсутствующего ресурса, `409` для конфликта состояния.
- Коллекции MUST иметь ограниченный размер страницы, стабильную сортировку и
  верхнюю границу `limit`.
- Swagger SHOULD быть доступен в development/staging; в production — только за
  авторизацией или отключён.
- Изменение публичного контракта сопровождается обновлением Swagger и клиента.

### Конфигурация и жизненный цикл

- Конфигурация читается через `@nestjs/config` и MUST валидироваться при старте.
  При отсутствии обязательной переменной процесс должен завершиться сразу.
- `.env.example` хранит только имена и безопасные примеры, никогда реальные секреты.
- Development, test, staging и production используют отдельные credentials и базы.
- Приложение MUST корректно обрабатывать `SIGTERM`, закрывая HTTP, Prisma, Redis,
  BullMQ и незавершённые операции.
- Нужны отдельные endpoints:
  - liveness — процесс отвечает;
  - readiness — обязательные зависимости готовы.
- CORS задаётся allowlist-списком, а не `*` для production.
- HTTP security headers подключаются через Helmet.
- Rate limit обязателен как минимум для OTP, входа, загрузки файлов, поиска и
  остальных дорогих либо публичных endpoints.

## 4. Prisma, PostgreSQL и PostGIS

### Prisma

- В процессе NestJS MUST существовать один долгоживущий `PrismaClient`.
- Локально схема меняется через `prisma migrate dev`.
- В staging/production применяется только закоммиченная история через
  `prisma migrate deploy`; `db push` в production запрещён.
- SQL миграции MUST просматриваться до commit, особенно при удалении/переименовании
  полей и работе с PostGIS.
- Несовместимое изменение выполняется в несколько релизов:
  добавить новое → заполнить данные → переключить код → удалить старое.
- Seed MUST быть повторяемым и не создавать дубликаты.

### Модель данных

- Все внешние ключи, обязательность полей и уникальность SHOULD фиксироваться в БД,
  а не только в TypeScript.
- Денежные значения хранить в минимальных единицах целым числом либо в `Decimal`;
  `float/double` для денег запрещён.
- Время хранить в UTC (`timestamptz`), локальную зону применять только при вводе и
  отображении.
- Статусы бронирования и платежа хранить раздельно и менять только допустимыми
  переходами.
- Для конкурентных операций — бронирование слота, подтверждение платежа, списание —
  использовать транзакцию и ограничение/блокировку в БД. Проверка вида
  «сначала SELECT, потом INSERT» без защиты от гонки недостаточна.
- Удаление пользователя не должно уничтожать данные, которые требуется хранить по
  финансовым или юридическим причинам; правила retention документируются отдельно.

### Запросы и индексы

- Каждый список обязан иметь пагинацию.
- Избегать N+1 и получения полных записей, когда нужен небольшой `select`.
- Индекс добавляется под реальный фильтр, сортировку, join или ограничение.
- Перед добавлением сложного индекса проверять запрос через `EXPLAIN (ANALYZE,
  BUFFERS)` на репрезентативных данных.
- Отслеживать медленные запросы, блокировки, размер таблиц/индексов и использование
  соединений.

### Геоданные

- Для координат использовать единый SRID 4326 и один порядок `longitude, latitude`.
- Дистанции считать географическими функциями PostGIS с явными единицами измерения.
- Геопоиск SHOULD использовать GiST/SP-GiST индекс и ограниченный радиус.
- Точность координат должна соответствовать сценарию; точное местоположение не
  выдаётся пользователю, которому оно не требуется.

### Надёжность

- Production MUST иметь автоматические backup, понятные RPO/RTO и мониторинг
  неуспешных копий.
- Восстановление из backup проверяется регулярно: непроверенная копия не считается
  рабочей.
- Миграция проверяется на копии/эквиваленте production-данных до релиза с риском
  блокировки или потери данных.

## 5. Redis и BullMQ

- Redis доступен только из доверенной сети, с аутентификацией и TLS вне локальной
  машины.
- Все ключи имеют пространство имён, например `sosedi:otp:<phoneHash>`.
- Временные данные MUST иметь TTL. Команда `KEYS` в runtime-коде запрещена; для
  обхода использовать `SCAN`.
- Нельзя помещать в Redis открытый OTP, access/refresh token или KYC-данные.
- Для важных сессий/очередей настройка persistence и eviction выбирается явно.
- Устанавливаются предел памяти и алерты на memory usage, evictions и connection
  count.

Для BullMQ:

- Job MUST быть идемпотентным: повторный запуск не создаёт второй платёж, бронь или
  push-запись.
- Внешние события получают стабильный `jobId`/idempotency key.
- Retry используется только для временных ошибок; backoff экспоненциальный с
  ограниченным числом попыток и jitter.
- Ошибки валидации и бизнес-конфликты не повторяются автоматически.
- Должны наблюдаться waiting/active/delayed/failed, возраст старейшей job и число
  исчерпанных попыток.
- Завершённые и ошибочные job очищаются по понятной retention-политике.
- Worker завершает работу gracefully и перестаёт брать новые job до остановки.

## 6. Flutter, Riverpod, Dio и маршрутизация

### Dart и состояние

- Следовать Effective Dart и `flutter_lints`.
- Предпочитать `final`, `const` и неизменяемые модели.
- Freezed/json_serializable использовать для моделей, где генерация уменьшает
  ручной код и ошибки; сгенерированные файлы не редактировать.
- Riverpod provider не используется как хранилище эфемерного UI-состояния вроде
  выбранного цвета, состояния анимации или значения локального TextField.
- Асинхронное состояние представлять через `AsyncValue`/явный sealed-state и
  обязательно отображать loading, data и error.
- В `build()` использовать `ref.watch`; обработчик события использует `ref.read`.
  `select` применять только после подтверждённой проблемы с лишними rebuild.
- Provider не должен инициализироваться из `initState` ради запуска бизнес-логики;
  инициализация должна зависеть от provider graph.
- Зависимости заменяются через overrides в тестах.

### Сеть через Dio

- Использовать один настроенный клиент: base URL, connect/send/receive timeouts,
  общие headers и единое преобразование ошибок.
- Обновление access token MUST быть single-flight: параллельные `401` не запускают
  несколько refresh-запросов.
- Повторять автоматически только безопасные/idempotent запросы или запросы с
  idempotency key.
- При закрытии экрана отменять дорогие запросы через `CancelToken`, если результат
  больше не нужен.
- Логи Dio MUST удалять `Authorization`, cookies, телефон, OTP, документы, точные
  координаты и тела платёжных запросов. Полный body logging в production запрещён.
- Ошибки транспорта преобразуются в небольшое число доменных состояний:
  offline/timeout/unauthorized/forbidden/validation/server/unknown.

### GoRouter и UX

- Маршруты, guards/redirects и deep links описываются централизованно.
- Redirect зависит от состояния auth/onboarding/KYC, но не выполняет сетевые
  побочные эффекты.
- Deep link проверяет авторизацию и доступ к объекту, а не доверяет ID из URL.
- Каждый экран с данными MUST иметь loading, empty, error и retry состояния.
- Отдельно обрабатываются offline и отказ в permission.
- Использовать семантические labels, достаточный contrast, масштабирование текста и
  touch target не меньше платформенных рекомендаций.

### Производительность

- Длинные коллекции строятся лениво (`ListView.builder`/slivers).
- Не выполнять синхронный тяжёлый JSON/image/crypto-код на UI isolate.
- Предпочитать `const` widgets; не добавлять `Opacity`, clipping и saveLayer без
  необходимости.
- Изображения загружаются в размере, близком к отображаемому, кешируются и имеют
  placeholder/error state.
- Оптимизация принимается после измерения в profile mode и Flutter DevItems, а не
  по субъективной плавности debug-сборки.

## 7. Карты, геолокация и permissions

- Permission запрашивается непосредственно перед функцией и сопровождается
  объяснением пользы.
- Отказ, постоянный отказ и отключённая геолокация имеют отдельные пользовательские
  сценарии.
- Движение карты debounce/throttle-ится; новый запрос отменяет устаревший.
- Для большого числа меток использовать кластеризацию и серверное ограничение
  области/радиуса.
- API-ключ карты не является настоящим секретом внутри мобильного bundle, поэтому
  он MUST быть ограничен bundle ID/package name, платформой и разрешёнными API.
- Точные координаты не попадают в аналитику, crash reports и push.

## 8. Аутентификация, авторизация и персональные данные

- OTP хранится только в виде стойкого hash/HMAC, имеет короткий TTL, ограничение
  попыток и rate limit по телефону, IP и устройству.
- Ответ запроса OTP не должен раскрывать существование пользователя.
- Access token короткоживущий; refresh token ротируется, хранится безопасно и может
  быть отозван по устройству/сессии.
- В Flutter токены хранятся в `flutter_secure_storage`; `shared_preferences`
  разрешён только для несекретных настроек.
- Каждый endpoint проверяет доступ к конкретному объекту. Наличие валидного JWT не
  заменяет object-level authorization.
- Роль из request body/query не считается доверенной.
- Административные и KYC-действия MUST иметь неизменяемый audit log: actor, action,
  target, timestamp, requestId и безопасный набор изменений.
- Admin/operator действия MUST использовать MFA/step-up и отдельные capabilities;
  web-сессия не хранит JWT/refresh в `localStorage`, использует secure `HttpOnly`
  cookie, CSRF-защиту, CSP и запрет встраивания во frame.
- Доступ к production и персональным данным предоставляется по минимально
  необходимым правам и регулярно пересматривается.
- Должны быть описаны согласия, сроки хранения, экспорт и удаление данных в рамках
  заявленных требований 152-ФЗ. Юридические тексты проверяются профильным юристом.

## 9. S3, фотографии и KYC

- До сбора паспорта и селфи MUST пройти legal gate: необходимость, правовое
  основание, статус биометрии, согласие, допустимые ограничения функций, срок
  хранения и удаление.
- После payment-provider decision MUST быть выбрана ровно одна ADR-ветка:
  `PROVIDER_MANAGED` без local KYC upload либо `LOCAL_KYC` после legal gate.
- Bucket по умолчанию закрыт; публичность выдаётся только явно.
- Только для `LOCAL_KYC` документы находятся в отдельном private bucket/prefix с
  отдельными правами и аудитом; при `PROVIDER_MANAGED` Sosedi их не собирает.
- Upload проверяет MIME, расширение, magic bytes, размер и разрешение изображения.
- Имя объекта генерирует сервер; исходное имя пользователя не используется как key.
- Presigned URL имеет минимальный scope и короткий срок жизни.
- Включаются шифрование, versioning/lifecycle там, где это соответствует retention.
- Метаданные EXIF, особенно GPS, удаляются, если они не нужны продукту.
- Для пользовательских файлов SHOULD предусматриваться malware scanning до выдачи
  другим пользователям.

## 10. Бронирования и YooKassa

> **Изменение решения от 25.07.2026:** раньше production-путь предполагал
> checkout + webhook без hold/split/выплаты владельцу. Теперь до интеграции
> monetized MVP разрешён только через согласованную «Безопасную сделку» ЮKassa;
> оплата при передаче остаётся pilot, где Sosedi не принимает деньги и берёт 0%
> комиссии. Причина — checkout-only не завершает P2P-расчет.

- Создание брони и резервирование доступности выполняются атомарно.
- Booking, Payment, Payout и Dispute имеют отдельные FSM; financial webhook не
  меняет Booking произвольным generic status endpoint.
- Цена, комиссия и скидка пересчитываются сервером из актуальных данных.
- Деньги передаются как minor units/`Decimal` в RUB; binary float запрещён.
- Клиент не переводит бронь или платёж в финальный статус самостоятельно.
- До provider approval разрешены доменная модель и fake provider, но не
  production-приём денег.
- В online-сценарии создание платежа использует idempotency key, связанный с
  внутренней попыткой оплаты.
- В online-сценарии webhook считается недоверенным вводом: проверить подлинность
  по актуальной документации провайдера и при необходимости запросить состояние
  платежа у YooKassa.
- Повторный webhook MUST быть безопасным и не дублировать финансовые операции.
- Сохранять provider payment ID, исходное событие/его hash, время и историю
  переходов, но не секреты и платёжные реквизиты.
- Для online-сценария финансовая сверка выполняется отдельной повторяемой
  процедурой.

## 11. Уведомления: FCM, RuStore Push и in-app inbox

- Backend хранит in-app уведомление как источник истины, а внешний push служит
  только сигналом о новом `eventId`.
- Небольшой `PushProvider` выбирает доступный транспорт без общей plugin
  architecture: FCM для GMS, RuStore Push для поддерживаемых Android-устройств,
  APNs через FCM либо напрямую для iOS.
- Token каждого транспорта связан с пользователем и установкой устройства;
  timestamp обновляется при регистрации/refresh.
- Недействительные и устаревшие tokens удаляются после ответов соответствующего
  провайдера.
- Push — сигнал, а не источник истины: после открытия клиент получает актуальные
  данные с API.
- Payload не содержит PII, точный адрес, телефон, KYC или финансовые подробности.
- Поведение foreground/background/terminated проверяется отдельно на Android и iOS.
- Открытие push маршрутизируется через проверенный deep link и повторную проверку
  авторизации.

> **Изменение решения от 25.07.2026:** раньше FCM был единственным каналом;
> теперь обязательны in-app inbox и возможность RuStore Push. Причина — Android
> без GMS и недопустимость единой внешней точки отказа.

## 12. Логи, мониторинг и GlitchTip

- Backend пишет структурированные JSON-логи с `timestamp`, `level`, `service`,
  `environment`, `requestId`, route, status и duration.
- Request ID принимается только в безопасном формате либо генерируется сервером и
  передаётся в job/исходящие запросы.
- Нельзя логировать Authorization/cookies, OTP, tokens, полные телефоны, KYC,
  платёжные тела и точные координаты.
- `sentry_flutter` и совместимые Sentry SDK используются только как клиенты
  GlitchTip self-hosted на VPS в РФ; hosted `sentry.io` запрещен.
- GlitchTip MUST получать environment и release; source maps/symbols загружаются
  для конкретного релиза.
- Перед отправкой событий настроить scrubbing PII и ограничить breadcrumbs.
- Минимальные метрики: error rate, p95 latency, запросы, DB pool, Redis memory,
  BullMQ lag/failures, OTP abuse, payment webhook failures и crash-free users.
- Алерт должен быть actionable: иметь owner, порог и короткую инструкцию реакции.

> **Изменение решения от 25.07.2026:** раньше слово Sentry одновременно означало
> SDK и hosted SaaS; теперь SDK сохранен ради совместимости, а события принимает
> только GlitchTip в РФ. Причина — доступность в РФ и локализация диагностических
> данных.

## 13. Docker и окружения

- Dockerfile использует pinned базовый образ, multi-stage build, `.dockerignore` и
  минимальный runtime.
- Production-процесс запускается не от root.
- В image не копируются `.env`, SSH-ключи, credentials и локальные build artifacts.
- Контейнер immutable: конфигурация и секреты поступают во время запуска.
- Для PostgreSQL, Redis и backend задаются healthchecks; порядок запуска не заменяет
  readiness и retry подключения.
- У контейнеров есть CPU/memory limits и политика логов в production.
- Compose для разработки и production разделяются override-файлами; development
  volume/watch не попадают в production.
- Состояние PostgreSQL и Redis хранится только в явных volumes; удаление volumes
  никогда не включается в обычную команду остановки.
- Образы пересобираются регулярно, а зависимости и base images сканируются на
  уязвимости.

## 14. Тесты и CI

### Обязательный минимум

- Для чистой функции/правила — unit test.
- Для NestJS service с БД/Redis — integration test на реальной совместимой
  инфраструктуре, когда mock не проверяет риск.
- Для критичного API — e2e: OTP/auth, права доступа, бронирование, платёжный webhook,
  выбранная identity/KYC-ветка и admin/operator actions.
- Для Flutter provider/service — unit test; для важных экранных состояний — widget
  test; для главного пользовательского пути — небольшой integration smoke test.
- Обязательно тестировать повтор запроса, параллельные бронирования, повтор webhook,
  истёкший token, отсутствие прав, timeout/offline и невалидный payload.
- Тест не зависит от порядка запуска, внешнего production-сервиса или текущего
  времени без controllable clock.

### CI

Перед merge из чистого checkout MUST проходить:

```bash
make ci
```

CI SHOULD выполнять:

1. воспроизводимую установку (`npm ci`, `flutter pub get` по lockfile);
2. Prisma generate и проверку миграций;
3. форматирование/lint/analyze;
4. unit и integration/e2e тесты;
5. backend build;
6. Android build и периодический iOS build на macOS runner;
7. dependency/secret/container scanning перед production.

Build artifacts и исходники сторонних пакетов не анализируются. В частности,
`mobile/build/`, `.dart_item/` и iOS `SourcePackages` MUST быть исключены/очищены
перед `flutter analyze`. Analyzer запускается на собственном коде, а не на
сгенерированных зависимостях.

Нестабильный тест нельзя просто перезапускать до зелёного результата: его причина
исправляется либо тест временно изолируется с owner и сроком возврата.

## 15. Git, PR и зависимости

- Ветка и PR содержат одну связанную задачу; механическое форматирование не
  смешивается с изменением поведения.
- Commit должен быть небольшим, понятным и собираться настолько, насколько это
  практично.
- В PR описать: что изменилось, зачем, как проверено, миграции/риски и screenshots
  для UI.
- Lockfiles коммитятся. Generated Prisma/Freezed файлы коммитятся только согласно
  выбранной текущей политике проекта — политика должна быть единой.
- Версии обновляются небольшими группами после release notes и тестов. Major update
  не объединяется с продуктовой задачей.
- Секреты никогда не коммитятся. При утечке удалить строку недостаточно — credential
  немедленно отзывается и ротируется.
- Для значимого, трудно обратимого решения достаточно короткого ADR:
  контекст → варианты → решение → последствия. ADR не нужен для обычной реализации.

## 16. Если появится web-клиент

React/Vite/Astro/Tailwind сейчас отсутствуют в репозитории, поэтому заранее вводить
их структуру не нужно. При появлении утверждённого web-клиента:

- выбрать **один** основной framework под задачу, а не смешивать React SPA и Astro
  без причины;
- включить TypeScript strict, ESLint, форматирование и проверку build в CI;
- держать server state отдельно от локального UI state;
- использовать semantic HTML, keyboard navigation и проверку accessibility;
- не помещать секреты в переменные Vite/Astro, доступные клиентскому bundle;
- Tailwind design tokens и SCSS не должны создавать две конкурирующие системы
  цветов, spacing и компонентов.

## 17. Definition of Done

Задача считается готовой, если:

- [ ] реализованы acceptance criteria и негативные сценарии;
- [ ] сохранены архитектурные границы и не добавлена преждевременная абстракция;
- [ ] входные данные валидируются, права проверяются на объекте;
- [ ] PII/secrets не попадают в логи, аналитику и push;
- [ ] добавлены тесты пропорционально риску;
- [ ] `make ci` проходит из чистого состояния;
- [ ] новая миграция просмотрена и имеет безопасный production-путь;
- [ ] Swagger, `.env.example` и документация обновлены при изменении контракта;
- [ ] проверены loading/empty/error/offline для изменённого UI;
- [ ] для изменения с эксплуатационным риском добавлены метрика/лог/алерт;
- [ ] нет случайных generated/build файлов и секретов в diff.

## 18. Ближайшие улучшения для текущего репозитория

Выполнено на этапе тестовой инфраструктуры:

- ✅ `mobile/build` и iOS `SourcePackages` исключены из Flutter analyzer;
- ✅ созданы изолированные test PostGIS/Redis, общий e2e bootstrap и начальные API
  smoke-тесты;
- ✅ coverage baseline и e2e включены в локальный `make ci` и GitHub Actions.
- ✅ Auth safety-net покрывает OTP/refresh concurrency, JWT/roles, mobile
  single-flight refresh, восстановление сессии, route guards и формы.

Оставшийся порядок — по влиянию на качество и выпуск продукта:

1. **P0:** добавить безопасную runtime-валидацию обязательных env-переменных и
   проверить, что production не публикует Swagger и не использует открытый CORS.
2. **P0:** применить Helmet и отдельные rate limits для OTP/auth/upload.
3. **P0:** добавить readiness/liveness и graceful shutdown Prisma/Redis/BullMQ.
4. **P0:** закрепить идемпотентность бронирований и платежных webhook ограничениями
   БД и integration-тестами гонок.
5. **P1:** включать более строгие TypeScript-флаги по одному, исправляя существующий
   код без большого отвлекающего rewrite.
6. **P1:** расширять e2e критическими сценариями и добавить в CI Android debug
   build.
7. **P1:** определить backup/restore, migration deploy и rollback/runbook до первого
   production-релиза.
8. **P1:** настроить structured logs, request ID, GlitchTip scrubbing и основные
   алерты.
9. **P2:** добавить регулярную проверку iOS build, dependency scanning и Flutter
    integration smoke для главного пути.

## 19. Официальные источники

Рекомендации адаптированы под ограничения Sosedi, а не скопированы как универсальная
архитектура:

- [Flutter — Guide to app architecture](https://docs.flutter.dev/app-architecture/guide)
- [Flutter — Testing overview](https://docs.flutter.dev/testing/overview)
- [Flutter — Performance best practices](https://docs.flutter.dev/perf/best-practices)
- [Effective Dart](https://dart.dev/effective-dart)
- [Riverpod — DO/DON'T](https://riverpod.dev/docs/root/do_dont)
- [go_router](https://pub.dev/packages/go_router)
- [NestJS — Validation](https://docs.nestjs.com/techniques/validation)
- [NestJS — Configuration](https://docs.nestjs.com/techniques/configuration)
- [NestJS — Helmet](https://docs.nestjs.com/security/helmet)
- [NestJS — Rate limiting](https://docs.nestjs.com/security/rate-limiting)
- [NestJS — Health checks](https://docs.nestjs.com/recipes/terminus)
- [Prisma — Connection management](https://docs.prisma.io/docs/orm/prisma-client/setup-and-configuration/databases-connections/connection-management)
- [Prisma Migrate](https://docs.prisma.io/docs/orm/prisma-migrate)
- [PostgreSQL — Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html)
- [PostgreSQL — Monitoring](https://www.postgresql.org/docs/current/monitoring.html)
- [Redis — Security](https://redis.io/docs/latest/operate/oss_and_stack/management/security/)
- [Redis — Client handling](https://redis.io/docs/latest/develop/reference/clients/)
- [BullMQ — Idempotent jobs](https://docs.bullmq.io/patterns/idempotent-jobs)
- [BullMQ — Retrying failing jobs](https://docs.bullmq.io/guide/retrying-failing-jobs)
- [Docker — Building best practices](https://docs.docker.com/build/building/best-practices/)
- [Docker Compose in production](https://docs.docker.com/compose/how-tos/production/)
- [Firebase — FCM token management](https://firebase.google.com/docs/cloud-messaging/manage-tokens)
- [Firebase — Receive messages in Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
- [AWS S3 — Security best practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [OWASP API Security Top 10](https://owasp.org/API-Security/editions/2023/en/0x11-t10/)

Этот документ пересматривается при изменении стека, после серьёзного инцидента или
перед новым этапом продукта. Новое правило добавляется только тогда, когда оно
предотвращает реальный риск или регулярно экономит время команды.
