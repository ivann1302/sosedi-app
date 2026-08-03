# Матрица доступа к endpoint

Дата инвентаризации: 25.07.2026.

Документ фиксирует две разные вещи:

- **текущее ограничение** — что фактически проверяет backend;
- **целевой доступ** — минимально допустимый доступ по `MVP_CHECKLIST.md`.

Целевой столбец не означает, что защита уже реализована. Матрица охватывает все
текущие HTTP routes backend, служебную Swagger-поверхность и семейства endpoint,
запланированные roadmap. Точные пути будущих endpoint определяются вместе с
доменным контрактом; до этого они помечены `TBD`.

## Термины доступа

- **public** — запрос не требует пользовательской или provider-аутентификации.
  Ответ содержит только явно публичные и минимизированные данные.
- **authenticated** — действующий короткий access token активного пользователя.
  Backend повторно проверяет, что пользователь существует, не удалён и не
  заблокирован, а `sessionVersion` токена совпадает с текущим поколением в БД.
- **owner** — объектная связь, например `Item.ownerId === actor.id`. Значение
  `UserRole.USER` само по себе не даёт доступ к чужому объекту.
- **participant** — пользователь является borrower или lender конкретного
  бронирования. Доступ дополнительно ограничивается состоянием брони и временным
  окном, если endpoint раскрывает адрес, контакт, evidence или финансовые детали.
- **admin-capability** — защищённая административная сессия с MFA, коротким
  временем жизни и конкретным полномочием: `MODERATION`, `SUPPORT`,
  `KYC_REVIEW` или `FINANCE`. Общая роль `ADMIN` не даёт полномочий автоматически;
  opaque session ID хранится только в `HttpOnly + Secure + SameSite=Strict`
  cookie, state-changing запрос требует `X-CSRF-Token`, а guard повторно читает
  полномочия из БД на каждом запросе, поэтому отзыв действует сразу.

OTP-код, refresh token и подпись/проверка provider webhook являются отдельными
credential-механизмами. Endpoint без access JWT, но с таким credential, не следует
считать обычным `public`.

Для object-level endpoint посторонний пользователь должен получить отказ до
чтения или изменения данных. Конкретный контракт `403` либо нераскрывающий
существование объекта `404` фиксируется в тесте endpoint.

Статусы тестов:

- **e2e** — граница доступа проверена через HTTP;
- **unit** — проверено только правило service/guard, без полного HTTP-контура;
- **нет** — отрицательной проверки доступа или privacy-контракта нет;
- **N/A** — для публичного endpoint нет объектной границы; минимизация ответа всё
  равно тестируется, если он способен вернуть чувствительные данные.

## Существующие backend routes

Все 82 controller routes имеют prefix `/api/v1`.

| № | Endpoint | Текущее ограничение | Целевой доступ | Чувствительный ввод/ответ | Отрицательный тест |
|---:|---|---|---|---|---|
| 1 | `GET /health` | Без guard; возвращает статический `ok` | `public`, только безопасный liveness без конфигурации и деталей зависимостей | Нет | N/A |
| 1a | `GET /health/live` | Без guard; только жизнь API process | `public`, безопасный liveness без dependency topology | Нет | unit/e2e |
| 1b | `GET /health/ready` | Без guard; DB, latest migration и Redis с bounded timeout | `public`; только `ok` либо generic `503 NOT_READY`, без credentials/topology | Нет | unit/e2e success + dependency failure |
| 2 | `POST /auth/otp/request` | Обязательный `X-Installation-Id` UUID v4; Redis-лимиты за 10 минут: phone `3`, installation `6`, client IP `60`; после них атомарный global cap `1000/24h` по умолчанию. IP/installation хешируются в ключах. `X-Forwarded-For` учитывается только через exact IP/CIDR allowlist непосредственных proxy | `public` + phone/IP/device/global SMS abuse limits и одинаковый ответ для существующего и нового пользователя | Телефон возвращается в ответе; raw IP/installation не входят в Redis key; при исчерпанном global cap OTP hash/provider call отсутствуют и увеличивается только low-cardinality `otp_global_limit` metric; provider failure удаляет только недоставленный hash | **unit/integration + e2e**: forged XFF без trusted proxy игнорируется; обрабатывается только nearest untrusted hop; wildcard и `/0` не запускаются; invalid installation, phone/device/IP, распределённый global cap, metric и SMS failure rollback покрыты |
| 3 | `POST /auth/otp/verify` | Обязательный `X-Installation-Id`; проверка одноразового OTP и лимита ошибок | Владелец действующего OTP; новая session привязана к установке | Телефон, OTP; ответ содержит access/refresh tokens и профиль | **e2e**: неверный, истёкший, повторный и конкурентный OTP |
| 4 | `POST /auth/refresh` | Подпись refresh token, одноразовый Redis `jti` и session registry; rotation сохраняет installation/session ID | Владелец активной device/session token family; replay старого token отзывает текущий token family | Refresh token; ответ содержит новые JWT и профиль | **e2e**: rotation, family-wide replay revocation и конкуренция |
| 5 | `POST /auth/logout` | Без access JWT; удаляет текущий `jti`, session metadata и user-session index | Владелец refresh-сессии; idempotent revoke выбранной сессии | Refresh token | **e2e**: отзыв одного токена |
| 5a | `GET /auth/sessions` | Access JWT + обязательный `X-Installation-Id`; читает только actor-bound Redis session index | `authenticated`, только self | Opaque session ID, installation ID, created/last-seen, current flag; JWT/refresh отсутствуют | **e2e**: две установки, current marker, отсутствие tokens |
| 5b | `DELETE /auth/sessions/:sessionId` | Access JWT; перед удалением metadata сверяет `userId` actor | `authenticated`, только своя сессия; чужой/просроченный ID обрабатывается идемпотентно | Opaque session ID | **e2e**: отзыв второй установки не затрагивает текущую |
| 5c | `DELETE /auth/sessions` | Access JWT; атомарно увеличивает DB `sessionVersion`, затем удаляет известные Redis sessions | `authenticated`, только self; немедленный logout all | Только status | **e2e**: все access/refresh становятся недействительны |
| 5d | `POST /auth/step-up/data-export/otp/request` | Access JWT + обязательный UUID v4 `X-Installation-Id`; общий phone/IP/device/global SMS abuse limit | `authenticated`, только self; свежий SMS factor для экспорта | Собственный телефон и TTL; OTP в ответе отсутствует | **unit + e2e**: общий OTP abuse contract и authenticated route |
| 5e | `POST /auth/step-up/data-export/otp/verify` | Access JWT; одноразовый OTP создаёт Redis-backed JWT на 5 минут, привязанный к actor, `sessionVersion` и purpose `DATA_EXPORT` | `authenticated`, только self; токен не является access/refresh credential | Одноразовый step-up token | **unit + e2e**: purpose/actor/session binding, истечение и replay |
| 6 | `GET /categories` | Без guard; только активные категории `ALLOWED`, с обязательным `safetyNotice` | `public` | Публичные данные категории и safety-предупреждение | N/A |
| 7 | `GET /categories/:slug` | Без guard; только активная категория `ALLOWED`, с обязательным `safetyNotice` | `public` | Публичные данные категории и safety-предупреждение | **unit + e2e**: active `ALLOWED` доступна; `RESTRICTED` slug получает `404` |
| 8 | `GET /items` | Без guard; только `APPROVED`, активная разрешённая категория и активный owner; отдельный public DTO возвращает модерируемый район, стабильную coarse-cell `SPARSE`, distance bucket и только preview/thumbnail; radius filter, distance sort и bucket используют ту же public point | `public`; сохранять минимизированный DTO, а более точную сетку вводить только после надёжной server-side оценки плотности | Публичный профиль owner; exact coordinates используются только для server-side derivation coarse-cell, адрес и `originalUrl` не выбираются; наружу эти поля не возвращаются | **e2e**: list/card дают одинаковую coarse-cell, small-radius geo следует public point и private fields отсутствуют; **unit**: фильтрация, whitelist, bucket и повторная visibility-проверка после raw query |
| 9 | `GET /items/:id` | Без guard; только `APPROVED`, активная разрешённая категория и активный owner; тот же public DTO, что у списка | `public`; тот же минимизированный DTO, что у списка | Публичный профиль owner; exact location и original photo отсутствуют | **e2e**: общий privacy-контракт list/card; **unit**: статус/owner |
| 10 | `GET /auth/me` | `JwtAuthGuard`, actor берётся из `sub` | `authenticated`, только self | Телефон, роль, KYC status, block status | **e2e**: refresh-as-access, JWT без `sub`, blocked/deleted actor; anonymous guard проверен на `/users/me` |
| 11 | `GET /users/me` | Class-level `JwtAuthGuard`, только self route; route с произвольным user ID отсутствует | `authenticated`, только self | Телефон, профиль, роль, KYC status | **e2e**: запрос без JWT; посторонний не может получить профиль по user ID |
| 12 | `PATCH /users/me` | Class-level `JwtAuthGuard`; изменяет actor из `sub`; `id`, `role`, `avatarUrl` и другие undeclared fields отклоняются | `authenticated`, только self; avatar меняется только через quarantine upload | Имя и город | **e2e**: overposting чужого `id`/`ADMIN` и прямого avatar URL отклонён; **unit**: разрешённые поля |
| 13 | `DELETE /users/me` | Class-level `JwtAuthGuard`; аутентифицированный запрос является явным подтверждением закрытия. Serializable transaction всегда ставит `deletedAt` и увеличивает `sessionVersion`; при нетерминальной Booking, открытом dispute ticket или связанной Payment/KYC записи возвращает `PENDING_OBLIGATIONS` и сохраняет PII, иначе сразу возвращает `ANONYMIZED`. Идемпотентный finalizer каждые 15 минут повторно проверяет закрытые аккаунты и очищает PII после исчезновения blockers | `authenticated`, только self; закрытый actor сразу теряет все сессии и публичную видимость. Payment/KYC трактуются консервативно как retention-sensitive до отдельных Refund/Payout/legal-hold моделей | Состояние аккаунта и связанных обязательств; PII не возвращаются после ответа | **unit + e2e**: каждый blocker откладывает только anonymization; active Booking не мешает немедленному session revoke/public hide; после terminal Booking finalizer очищает PII; access/refresh всех устройств не оживают |
| 13a | `GET /users/blocks` | JWT; blockerId всегда actor | `authenticated`, только собственный block list | ID/display name заблокированных пользователей, без телефона | **e2e**: другой пользователь видит пустой собственный список |
| 13b | `POST /users/blocks/:targetUserId` | JWT; self-block запрещён, upsert идемпотентен | `authenticated`, только actor→target; запрещает новые Booking в обе стороны | Минимальный blocked profile | **unit + e2e**: repeat idempotent, self-block `400`, оба направления блокируют новую Booking |
| 13c | `DELETE /users/blocks/:targetUserId` | JWT; delete predicate включает blockerId actor | `authenticated`, только собственная связь; idempotent | Только target ID и `blocked=false` | **e2e**: существующая Booking остаётся доступной до и после unblock |
| 13d | `POST /users/me/data-export` | JWT + одноразовый `DATA_EXPORT` step-up token; token потребляется до repeatable-read snapshot | `authenticated`, только self; прямой UTF-8 JSON не сохраняется backend | Свои profile/listings, participant bookings, inbox/support, acceptances, допустимая financial history, file manifest и retention descriptions; чужие IDs/контакты/адреса, secrets, provider payload и storage URL исключены | **unit + e2e**: adversarial redaction, invalid/replayed step-up получает `401`, JWT/refresh/step-up отсутствуют в export |
| 14 | `POST /items` | JWT + роль `USER`; backend назначает actor владельцем, требует активную категорию `ALLOWED`, общие поля состояния/комплектации/передачи, четыре явных подтверждения и актуальную версию правил публикации; до отдельного утверждения залога `depositAmount` допускает только отсутствие, `null` или `0` | `authenticated`; создаваемый `ownerId` всегда равен actor, а публикация не меняет роль; `RESTRICTED`/`PROHIBITED`, неполное подтверждение, устаревшая версия и ненулевой залог отклоняются server-side | Точный адрес/координаты и полный приватный Item DTO; в БД фиксируются server timestamp, способ принятия, версия правил и snapshot категорийного `safetyNotice` | **e2e**: обязательные поля, category policy, отказ для неполного/устаревшего подтверждения и ненулевого залога, acceptance snapshot и неизменность роли |
| 14a | `GET /items/mine` | JWT + роль `USER`; ownerId всегда берётся из actor, произвольный userId не принимается | `authenticated`, только собственные объявления во всех moderation statuses | Private Item DTO с точным адресом/координатами только для владельца | **unit + e2e**: anonymous `401`, чужие объявления исключены, private DTO доступен владельцу |
| 15 | `PATCH /items/:id` | JWT + роль `USER`; Prisma predicate одновременно проверяет `id + ownerId`, поэтому чужой и отсутствующий Item получают одинаковый `404` без загрузки приватной записи. Любое непустое изменение требует отсутствия Booking в `PENDING/CONFIRMED/ACTIVE/RETURNED`, иначе `409 ITEM_HAS_UNFINISHED_BOOKINGS`; допустимое изменение переводит Item в `PENDING` для повторной модерации | `owner`; до Booking snapshot запрещено менять цену, адрес и другие модерируемые условия при незавершённой аренде | Точный адрес, координаты, цена, полный приватный DTO | **unit + e2e**: чужой owner получает нераскрывающий `404`; незавершённая Booking сохраняет Item без изменений; `COMPLETED/CANCELLED` не блокируют повторную модерацию |
| 16 | `PATCH /items/:id/hide` | JWT + роль `USER`; тот же predicate `id + ownerId`; Booking в `PENDING/CONFIRMED/ACTIVE/RETURNED` возвращает `409 ITEM_HAS_UNFINISHED_BOOKINGS` | `owner`; скрытие разрешено только без незавершённой Booking, повторное скрытие идемпотентно | Полный приватный Item DTO | **unit + e2e**: чужой owner получает `404`; незавершённая Booking не позволяет скрыть Item и не меняет его |
| 17 | `POST /uploads/presigned-url` | JWT + актуальный `sessionVersion` + роль `USER`; для `ITEM_PHOTO` Prisma predicate проверяет `id + ownerId`; `AVATAR` всегда привязан к actor; `KYC_DOCUMENT` немедленно получает `403` до проверки файла и обращения к S3 | Для item photo — активный `owner`; для avatar — только self; одноразовый upload intent. `KYC_DOCUMENT` всегда отклоняется до `ACCEPTED LOCAL_KYC` ADR | Presigned URL, private quarantine bucket/key; запрещённый KYC purpose не раскрывает storage details | **unit + e2e**: отозванная сессия, KYC gate, avatar self-binding и чужой Item |
| 18 | `POST /uploads/item-photos/confirm` | JWT + роль `USER`; DTO разрешает только item-photo поля; ownership проверяется predicate `id + ownerId`; незавершённая Booking блокирует новый presign/confirm, новое фото возвращает Item в `PENDING`, replay остаётся идемпотентным | `owner` + принадлежащий actor одноразовый intent; проверка bucket/key/MIME/size/magic bytes/object и idempotency | Object key; URL остаются `null` до безопасной обработки | **e2e**: KYC purpose и чужой Item отклонены, новая запись не создана; **unit**: booking block, повторная модерация и replay |
| 18a | `POST /uploads/avatars/confirm` | JWT + роль `USER`; actor/entity-bound `AVATAR` intent; повторная проверка bucket/key/MIME/size/magic bytes; Sharp decode/re-encode удаляет metadata до публикации | `authenticated`, только self; профиль обновляется только после успешной обработки quarantine object | Новый публичный WebP avatar URL; исходный private object удаляется/дочищается | **unit + e2e**: полный presign → confirm, direct URL bypass отклонён |
| 19 | `GET /uploads/:intentId/download-url` | JWT + роль `USER`; actor-bound intent, owner predicate, private bucket/key и существование объекта проверяются до presign | `owner` только для своего непросроченного `ITEM_PHOTO` intent | Presigned GET URL на 60 секунд; постоянный private URL отсутствует | **unit + e2e**: чужой actor получает нераскрывающий `404`; owner получает только короткий URL |
| 19a | `POST /bookings` | JWT + роль `USER`; payload содержит Item/даты и явно принятые offer/rental-rules versions; они точно сверяются с approved env, а Item/lender/rate/status/acceptance timestamp+method назначаются server-side; DB transaction + advisory locks по borrower и Item | `authenticated` borrower, не owner; актуальные версии и оба acceptance=true; только свободный inclusive период `APPROVED` Item; максимум 5 живых `PENDING` | Actor IDs, даты, server total, `PENDING` и TTL; exact address не возвращается; immutable snapshot хранит actor/time/method/versions acceptance | **unit + e2e**: закрытый gate `503`, missing/stale acceptance `409` без Booking, persistence evidence, date/self/price/pending/overlap/concurrency |
| 19b | `GET /items/:itemId/unavailable-periods` | JWT + роль `USER`; Item выбирается по `id + ownerId` actor | `owner` | Собственные закрытые интервалы календаря | **unit + e2e**: чужой Item получает нераскрывающий `404`; owner видит только свой период |
| 19c | `POST /items/:itemId/unavailable-periods` | JWT + роль `USER`; DB transaction и advisory lock по Item; пересечение с живой Booking/интервалом отклоняется | `owner`; не изменяет существующую Booking | Собственный календарь и даты бронирований без данных borrower | **unit + e2e**: ownership, Booking conflict и сохранение `CONFIRMED` |
| 19d | `DELETE /items/:itemId/unavailable-periods/:periodId` | JWT + роль `USER`; Item и period связаны под advisory lock | `owner`; только период своего Item | ID собственного календарного интервала | **unit + e2e**: чужой actor получает `404` и период остаётся; owner удаляет свой период |
| 19e | `GET /inbox` | JWT + роль `USER`; recipient всегда actor | `authenticated`, только собственные события | Opaque event и минимальный booking/support/item ID, тип, read state | **e2e**: borrower/lender/owner получают событие, посторонний — пустой список |
| 19f | `GET /inbox/:eventId` | JWT + роль `USER`; predicate одновременно проверяет recipient и participant Booking, author Support либо owner Item | `recipient + связанная entity` | Минимальные dates/amount/status либо entity ID без адреса, контакта и actor IDs | **e2e**: посторонний получает нераскрывающий `404`, moderation owner получает только свой Item event |
| 19g | `PATCH /inbox/:eventId/read` | JWT + роль `USER`; unique `(eventId, recipientId)` | `recipient`, idempotent | Read timestamp только собственной inbox-записи | **e2e**: повтор сохраняет тот же timestamp |
| 19h | `POST /bookings/:id/confirm` | JWT + роль `USER`; Booking predicate проверяет lender; locks Booking и Item, затем повторно читает state | `lender`, только живой `PENDING`; одна заявка выигрывает, пересекающиеся `PENDING` получают явную отмену | Booking participant IDs, даты, сумма и новый status; без exact location | **unit + e2e**: wrong actor/state, два конкурентных confirm дают один `CONFIRMED` и один `CANCELLED` |
| 19h.1 | `POST /bookings/:id/cancel` | JWT + participant predicate; advisory lock Booking; actor-derived reason | borrower/lender, только живой `PENDING`; retry той же стороны идемпотентен | `CANCELLED` и `BORROWER_CANCELLED` либо `LENDER_DECLINED`; без refund/fee | **e2e**: outsider `404`, обе стороны, retry даёт одну history/outbox, `CONFIRMED` остаётся неизменным |
| 19i | `GET /bookings` | JWT + роль `USER`; predicate `borrowerId/lenderId === actor` | `participant`, только собственные брони | Immutable pricing snapshot; exact handover/contact только в разрешённых states | **e2e**: actorRole, собственный список и state-based redaction |
| 19j | `GET /bookings/:id` | JWT + роль `USER`; predicate одновременно проверяет id и participant | `participant`; до утверждения dispute window exact handover/contact только `CONFIRMED/ACTIVE`, при `RETURNED/CANCELLED/COMPLETED` fail-closed скрыты | Snapshot суммы/условий; точный адрес/координаты и телефон условно | **e2e**: посторонний `404`, PENDING/RETURNED/CANCELLED redaction, CONFIRMED reveal, snapshot не меняется вслед за Item |
| 19k | `GET /bookings/:bookingId/acts` | JWT + роль `USER`; Booking participant predicate | `participant` | Автор, этап, timestamps и SHA-256 без storage URL | **e2e**: оба этапа доступны участнику, посторонний получает `404` |
| 19l | `POST /bookings/:bookingId/acts` | JWT + роль `USER`; participant/state и actor-bound одноразовый `BOOKING_EVIDENCE` intent; MIME/magic + safe image re-encode; server SHA-256 очищенных байтов | `participant`; `HANDOVER` только в `CONFIRMED`, `RETURN` только в `ACTIVE` | Private evidence metadata; object key хранится в БД, но не возвращается | **unit + e2e**: bucket/key/content validation, sanitization, stage state, один act на этап |
| 19m | `POST /bookings/:bookingId/acts/:actId/confirm` | JWT + роль `USER`; author не может подтвердить сам; shared Booking lock | Только второй `participant`; idempotent повтор того же confirmer | Confirmation metadata; атомарный `ACTIVE/RETURNED` transition + outbox | **e2e**: self-confirm `409`, second-party happy path обоих этапов |
| 19n | `GET /bookings/:bookingId/evidence/:evidenceId/download-url` | JWT + participant predicate через Act→Booking; только confirmed intent | `participant` | Presigned private GET URL на 60 секунд; storage key не возвращается отдельным полем | **unit + e2e adapter boundary**: outsider получает `404` до presign, participant получает URL; real RF S3 smoke остаётся release gate |
| 19o | `POST /bookings/:id/extend` | JWT + participant predicate; validated endDate | `participant`, но extension отключён для MVP | Только стабильная ошибка без изменения Booking/history | **e2e**: participant `409 BOOKING_EXTENSION_NOT_SUPPORTED`, посторонний `404`, state/history неизменны |
| 19p | `POST /support/tickets` | JWT + роль `USER`; actor всегда становится author, тип принудительно `GENERAL` | `authenticated`, только создание обычного нефинансового обращения | Subject и приватное сообщение | **unit + e2e**: DTO bounds, создаётся только `GENERAL` |
| 19q | `GET /support/tickets` | JWT + роль `USER`; predicate `userId === actor AND type === GENERAL` | `authenticated`, только собственные обычные обращения; financial dispute отделён | Исходное сообщение и ответ поддержки | **unit + e2e**: чужой `GENERAL` и собственный `DISPUTE` исключены |
| 19r | `GET /support/tickets/:id/messages` | JWT + predicate `ticket.userId === actor`; только `GENERAL` | author конкретного обращения | Append-only thread и hashes вложений без storage key/URL | **e2e**: чужой author получает нераскрывающий `404` |
| 19s | `POST /support/tickets/:id/messages` | JWT + тот же author predicate; до трёх actor/ticket-bound `SUPPORT_ATTACHMENT` intents безопасно перекодируются и потребляются атомарно | author незакрытого обращения | Текст, SHA-256 очищенного private attachment; постоянный URL отсутствует | **e2e**: intent binding, sanitization, чужой ticket и private download boundary |
| 19t | `GET /support/tickets/:id/attachments/:attachmentId/download-url` | JWT + author/ticket/attachment predicate и confirmed intent | author конкретного обращения | Presigned private GET URL на 60 секунд | **e2e**: чужой author получает `404`, owner получает короткий URL |
| 19u | `POST /reports` | JWT + роль `USER`; target/reason matrix и object predicate, Redis `5/час`, PostgreSQL advisory lock и duplicate window 24 часа | `authenticated`; нельзя жаловаться на собственный Item/User, для Booking нужен participant | Reporter, цель, описание; identity reporter не выдаётся target | **e2e**: concurrent duplicate `201/409`, шестая жалоба `429`, Item не меняется |
| 19v | `POST /device-tokens` | JWT + обязательный UUID v4 `X-Installation-Id`; serializable upsert `(user, installation, provider)` с тремя retry только для Prisma `P2034`, provider token переносится с прежнего user | `authenticated`, только текущий user/device; `RUSTORE` только Android | Token хранится в БД, но не возвращается API | **unit + e2e**: конкурентный upsert возвращает один ID; bounded retry, rotation/transfer, RUSTORE+iOS |
| 19w | `DELETE /device-tokens/:id` | JWT + predicate `id + userId` | `authenticated`, только собственный token; чужой/отсутствующий idempotent | Response только id/removed, без token | **e2e**: чужое удаление не меняет запись |
| 20 | `POST /categories` | Короткая TOTP-backed opaque Redis admin-сессия в защищённой cookie + CSRF + `MODERATION`; mutation и минимизированный audit атомарны | `admin-capability(MODERATION)` | Данные категории; audit не копирует `safetyNotice` | **e2e**: обычный access JWT получает `401`; admin без capability получает `403`; **unit**: audit |
| 21 | `PATCH /categories/:id` | Admin-сессия + `MODERATION`; DTO не содержит `isActive`, поэтому generic update не меняет состояние категории; content mutation и audit атомарны | `admin-capability(MODERATION)` | Данные категории; публичные управляющие поля в before/after | **e2e**: `isActive` отклонён, content update создаёт audit; **unit**: redacted audit |
| 22 | `PATCH /categories/:id/disable` | Admin-сессия + `MODERATION`; отдельная команда деактивации и audit в одной транзакции | `admin-capability(MODERATION)` + проверка влияния на активные объявления | Данные категории; только `isActive` в before/after | **unit + e2e**: disable command, capability boundary и audit |
| 23 | `GET /admin/users` | Короткая opaque Redis admin-сессия после TOTP/recovery step-up + `MODERATION` | `admin-capability(MODERATION)`; SUPPORT использует только actor-bound ticket context | Телефоны, профили, KYC/block/delete status | **e2e**: access JWT и SUPPORT-only отклонены; MODERATION получает список; отзыв capability действует сразу |
| 24 | `GET /admin/users/:id` | Та же admin-сессия + `MODERATION` | `admin-capability(MODERATION)`; KYC-документы этим endpoint не выдаются | Телефон и полный admin profile | **e2e**: обычный actor/access JWT и SUPPORT-only отклонены |
| 25 | `GET /admin/items/pending` | Admin-сессия + `MODERATION` | `admin-capability(MODERATION)` | Модерируемый текст, состояние, цена, район и обработанные photo URL; адрес, координаты и телефон owner не выбираются | **unit + e2e**: `SUPPORT` получает `403`, `MODERATION` разрешена, private location/contact отсутствуют |
| 26 | `PATCH /admin/items/:id/approve` | Admin-сессия + `MODERATION`; команда только из `PENDING`, иначе `409`; один audit log | `admin-capability(MODERATION)` | Тот же минимизированный moderation Item DTO без адреса/координат/телефона | **unit + e2e**: capability boundary, PENDING happy path, repeat `409`, один audit |
| 27 | `PATCH /admin/items/:id/reject` | Admin-сессия + `MODERATION`; команда с reason только из `PENDING`, иначе `409` | `admin-capability(MODERATION)` | Причина и тот же минимизированный moderation Item DTO | **unit + e2e**: capability boundary; approved Item не возвращается в REJECTED |
| 28 | `POST /admin/session/step-up` | Обычный access JWT активного `ADMIN` + TOTP либо одноразовый recovery code; до создания сессии обязателен redacted audit успешного step-up; recovery code потребляется вместе с отдельным request-metadata audit | `ADMIN`; создаёт opaque Redis MFA-сессию максимум на 15 минут | Только TTL; session ID, CSRF token и MFA/recovery code никогда не попадают в audit; для recovery сохраняется только remaining before/after | **unit + e2e**: owner `403`, access JWT/SMS OTP не открывают admin API, cookie flags, TTL, request metadata и recovery replay проверены |
| 29 | `DELETE /admin/session` | Действующая cookie admin-сессия + `X-CSRF-Token`; Redis key удаляется до обязательного redacted audit | Только текущий opaque session ID | Session ID/cookie/CSRF не логируются; audit содержит actor, request metadata и active→revoked | **e2e**: без CSRF `403`; после revoke та же cookie получает `401`, audit создан без session secret |
| 30 | `PATCH /admin/users/:id/block` | Admin-сессия + `MODERATION`; отдельная команда атомарно блокирует пользователя, увеличивает `sessionVersion` и пишет audit с причиной; незавершённая Booking блокирует обычную команду | `admin-capability(MODERATION)`; self-block запрещён; emergency safety flow требует отдельного audited процесса | Статус пользователя; причина остаётся в audit | **unit + e2e**: active Booking даёт `USER_HAS_UNFINISHED_BOOKINGS`; старые access/refresh не оживают после снятия флага; presign получает `401`; audit создан |
| 31 | `POST /admin/session/totp/setup` | Access JWT активного `ADMIN`; запрещён после первого enrollment; pending secret доступен только после redacted audit, при audit failure Redis key удаляется | Только initial MFA enrollment | Однократно возвращает Base32 secret и `otpauthUri`; pending secret зашифрован в Redis и отсутствует в audit | **e2e**: не-admin получает `403`; request metadata audit не содержит secret |
| 32 | `POST /admin/session/totp/confirm` | Access JWT активного `ADMIN` + код pending TOTP; credential, recovery hashes и redacted audit создаются в одной транзакции | Только initial MFA enrollment | Recovery codes показываются один раз; в БД только encrypted TOTP и hashes; audit содержит requestId/IP/device и `mfaEnabled` before/after без secrets | **e2e**: подтверждающий TOTP нельзя повторно использовать для step-up, recovery code одноразовый, request metadata audit без secret/codes |
| 33 | `GET /admin/session` | Действующая opaque cookie admin-сессия | Текущий operator; capabilities и отзыв доступа повторно проверены по БД | Self UUID, список capability и оставшийся TTL без телефона, token/session ID | **e2e**: self UUID, cookie обязательна, пустые capability не расширяют доступ; отзыв роли немедленно даёт `401`, прежний audit остаётся |
| 34 | `GET /admin/support/tickets` | Admin-сессия + `SUPPORT`; финансовые dispute исключены до ADR | `admin-capability(SUPPORT)` | Сообщение, display name, короткий user ID и безопасный bookingId/reason context без телефона, адреса и денег | Operator `GENERAL` queue сортирует deterministic SLA/priority, показывает assignee; **e2e**: access JWT и admin без `SUPPORT` отклонены |
| 35 | `PATCH /admin/support/tickets/:id/assign-self` | Admin-сессия + `SUPPORT` + CSRF; только свободное `GENERAL`, конкурентное назначение не перезаписывается | `admin-capability(SUPPORT)`; назначение только на текущего оператора | Assignee и status без содержимого в audit | **unit + e2e**: capability/CSRF boundary, audit создан |
| 36 | `PATCH /admin/support/tickets/:id/reply` | Admin-сессия + `SUPPORT` + CSRF; только свободное или назначенное текущему operator `GENERAL`, один ответ, атомарный audit без текста сообщения | `admin-capability(SUPPORT)` | Ответ поддержки; request metadata в audit | **unit + e2e**: capability/CSRF boundary, audit создан |
| 37 | `GET /admin/support/tickets/:id/messages` | Admin-сессия + `SUPPORT`; только `GENERAL` | `admin-capability(SUPPORT)` | Приватный thread без постоянных file URL | **e2e**: capability/session boundary |
| 38 | `POST /admin/support/tickets/:id/messages` | Admin-сессия + `SUPPORT` + CSRF; только свободное или назначенное текущему operator обращение; redacted audit | `admin-capability(SUPPORT)` | Текст ответа и attachment hashes; audit содержит только count | **e2e**: capability/CSRF, thread и audit |
| 39 | `POST /admin/support/tickets/:id/attachments/presigned-url` | Admin-сессия + `SUPPORT` + CSRF; actor/ticket-bound private intent | `admin-capability(SUPPORT)` | Private presigned POST, bucket/key | Guard покрыт общим admin e2e; object binding покрыт upload unit/user e2e |
| 40 | `GET /admin/support/tickets/:id/attachments/:attachmentId/download-url` | Admin-сессия + `SUPPORT`; повторная ticket/attachment проверка | `admin-capability(SUPPORT)` | Presigned private GET URL на 60 секунд; после authorization и до presign пишется `SUPPORT_ATTACHMENT_DOWNLOAD_REQUESTED` без URL/key/hash/содержимого | Guard, object binding и минимизированный audit покрыты e2e |
| 40a | `PATCH /admin/support/tickets/:id/close` | Admin-сессия + `SUPPORT` + CSRF; атомарно только незакрытый `GENERAL`, свободный или назначенный текущему operator | `admin-capability(SUPPORT)` | Статус/assignee; audit содержит только переход и request metadata, пользователь получает inbox event | **unit + e2e**: CSRF, ownership назначения, повтор/закрытый thread и audit/outbox |
| 41 | `GET /admin/reports` | Admin-сессия + `MODERATION`; только открытые жалобы, минимальный live target context | `admin-capability(MODERATION)` | Reporter id/name и приватное описание только operator | **e2e**: access JWT и `SUPPORT` capability отклонены |
| 42 | `PATCH /admin/reports/:id/decision` | Admin-сессия + `MODERATION` + CSRF; advisory lock, одно решение; `dismiss` любой target, `hide` только Item, `block` только User без незавершённых Booking | `admin-capability(MODERATION)` | Причина и target mutation; при `hide` owner получает нейтральный Item event без report/reporter/reason | **e2e**: capability/CSRF, Item hide, redacted audit и recipient-only inbox |

`PhotoProcessingWorker` перед чтением original и записью preview повторно
проверяет, что владелец Item не заблокирован и не удалён; иначе job завершается
без S3/DB side effects. WebSocket gateway в MVP сейчас отсутствует. Если он будет
добавлен, handshake и каждое чувствительное действие обязаны проверять активного
actor и тот же `sessionVersion`; отсутствие gateway является deny-by-default.

Client IP для rate limit и admin audit проходит через единый `getClientIp()`.
`TRUSTED_PROXY_IPS` по умолчанию пуст, принимает только перечисленные IP/CIDR и
не разрешает wildcard/`0.0.0.0/0`/`::/0`. Каждый реальный ingress proxy должен
быть перечислен, а proxy обязан добавлять фактический remote address в
`X-Forwarded-For`. Payment/provider webhook пока отсутствует; при его добавлении
этот же client IP contract не заменяет обязательную проверку подписи provider.

## Существующая Swagger-поверхность

Swagger регистрируется отдельной `configureSwagger()` только вне production.

| Endpoint | Текущее ограничение | Целевой доступ | Чувствительность | Отрицательный тест |
|---|---|---|---|---|
| `GET /api/docs` | Публично только в development/test; route отсутствует в production | Отключён в production | Полная карта API, DTO и auth-схема | Production `404` в `swagger.setup.spec.ts` |
| `GET /api/docs-json` | Публично только в development/test; route отсутствует в production | Отключён в production | Машиночитаемый OpenAPI contract | Production `404` в `swagger.setup.spec.ts` |
| `GET /api/docs-yaml` | Публично только в development/test; route отсутствует в production | Отключён в production | Машиночитаемый OpenAPI contract | Та же registration policy |

Статические ресурсы Swagger UI считаются частью `/api/docs` и наследуют ту же
production-политику.

## Существующая operational-процедура

`make backend-admin-bootstrap` создаёт первого администратора без HTTP endpoint:
требует одноразовые phone/capabilities/confirmation env, берёт PostgreSQL
advisory lock, отказывается при существующем `ADMIN`, не выдаёт `KYC_REVIEW` или
`FINANCE` и пишет audit без телефона. Повторный и конкурентный запуск проверены
e2e; инструкция находится в `docs/first-admin-bootstrap.md`.

## Планируемые семейства endpoint

Строка `TBD` является обязательством определить точный method/path и OpenAPI
contract до реализации, а не разрешением оставить доступ неописанным.

| Раздел roadmap | Логические endpoint, method/path `TBD` | Целевой доступ и объектная проверка | Чувствительный ответ | Обязательные отрицательные тесты |
|---|---|---|---|---|
| Users / account lifecycle | Закрытие аккаунта, завершение сессий и синхронный self-service JSON export реализованы выше; async archive нужен только при подтверждённом превышении безопасного размера ответа | `authenticated`, только self; export требует отдельный одноразовый SMS step-up | Пользовательский export с redaction третьих лиц, статус обязательств при закрытии | Чужой account ID, повтор step-up token, blocked/deleted actor, adversarial third-party/provider/storage payload |
| Items private | Список/карточка/редактирование своих объявлений и participant handover details реализованы выше | Для own item — `owner`; для адреса/контакта — `participant` только в утверждённом состоянии/окне | Точный адрес, координаты, контакт, moderation reason | Чужой owner; посторонний/анонимный; `PENDING`/`CANCELLED`/истёкшее окно |
| Upload intents и private files | Item/avatar/support/booking-evidence intents и owner/participant/operator download реализованы; KYC gated, report evidence TBD | `participant` или конкретная `admin-capability` по purpose и entity; intent связан с actor/entity/bucket/key | Presigned URL, private object/evidence | Чужая entity, key/MIME/size substitution, replay, parallel confirm, expired intent |
| Admin identity/session | TOTP/recovery, step-up/revoke реализованы; session list/revoke-all остаются будущими | Отдельная MFA-backed opaque session в `HttpOnly + Secure + SameSite=Strict` cookie и CSRF для mutations | Session/recovery metadata без secret | Stale/revoked session, CSRF, self-promotion, recovery replay |
| Booking core | Создание и карточка брони; список своих броней; lender unavailable periods | Создание — `authenticated` borrower, не owner собственного Item; чтение — `participant`; calendar mutation — `owner` | Booking snapshot, даты, цена и стороны | Self-booking, чужая бронь, прошлые/перевёрнутые даты, overlap/concurrency |
| Booking commands | Confirm, cancel, handover, return, no-show и утверждённый extension либо явный отказ | Отдельный command endpoint; конкретный actor, текущий state, ownership/participation и idempotency key | История переходов, причины, последствия refund/fee | Generic status update, неправильный actor/state, replay, concurrent transition |
| Handover/evidence | Получение точного pickup/dropoff; создание/подтверждение актов и evidence | `participant` только в `CONFIRMED/ACTIVE/RETURNED` и до конца handover/dispute window; audited support отдельно | Адрес, контакт, private photos/files/hash | Посторонний, отменённая бронь, закрытое окно, чужой file key |
| Inbox | Booking, support и moderation producers, list/read/details и безопасная mobile navigation реализованы; payment producer ждёт payment gate | `authenticated`, только recipient; детали повторно авторизуются по связанной entity | Минимальные Booking/Support/Item details | Чужой `eventId`, stale event, blocked/deleted actor, duplicate event |
| Dispute | Открытие/карточка спора; evidence; решение | Open/read/evidence — `participant`; решение — `admin-capability(dispute/finance)` + step-up | Evidence, reason, refund/payout amounts | Чужая бронь/спор, окно закрыто, resolver без capability, dispute-vs-payout race |
| Payments participant | Создание payment/deal attempt, confirmation URL, история payment/refund/payout/receipt | `participant` с actor-specific действием и подтверждённой Booking; online endpoints отсутствуют в `PAY_ON_HANDOVER` | Суммы, provider IDs, checkout URL, финансовая история | Чужая бронь/payment, повтор idempotency key, неверная сумма/currency/state |
| Payments provider/operator | Provider webhook; failed/stuck queue; refund/payout/corrective commands | Webhook — аутентичный provider credential + fresh provider object; действия — `admin-capability(finance)` + step-up | Provider event, финансовые записи; без PAN/CVC/raw PII | Fake/replay/out-of-order webhook, test/live mismatch, wrong capability, refund/payout race |
| KYC `PROVIDER_MANAGED` | Начало onboarding, нормализованный status; provider webhook/API refresh | Owner/recipient — `authenticated` self; callback — provider credential; Sosedi не получает документы | Только provider reference/status/reason | Mobile redirect spoof, чужой recipient, replay/expiry; отсутствие passport/selfie payload |
| KYC `LOCAL_KYC` | Presign/confirm approved documents; self status; reviewer queue/download/approve/reject | Только после `ACCEPTED LOCAL_KYC` ADR. Upload/status — self; review/download — `admin-capability(kyc-review)` + MFA/step-up и audit | Паспорт/селфи, consent, private download URL | До-gate upload, чужой document, reviewer без capability, неаудированный просмотр, retention expiry |
| Support | Создание/list своих `GENERAL`, structured booking issues, append-only thread, private image attachments и operator list/assign/reply/close реализованы; financial dispute остаётся TBD | User routes — author; booking issue требует participant + actor/state/date reason; operator — `admin-capability(support)` | Сообщения, private attachments, минимальный booking/reason context | Чужой ticket/booking/file, неверный actor/state/date, operator без capability, закрытый ticket mutation |
| Reports и user blocks | Создание report, rate/dedup, self-scoped block/unblock, operator queue и безопасный Item-owner notice реализованы; report evidence остаётся TBD | Создатель — `authenticated`; block — только self→target; решения — `admin-capability(moderation)` | Evidence и личность автора жалобы не раскрываются затронутой стороне | Чужая жалоба, массовый replay, self-block, operator без capability |
| Device tokens / push | Register/update/delete token и durable delivery/retry/invalid-token cleanup реализованы; FCM/RuStore adapters ждут store gate | `authenticated`, только токены текущего пользователя/device installation | Push token/device metadata; provider payload только `eventId` | Чужой token, provider/platform substitution, stale token, lease recovery и duplicate signal |
| Public legal/support web | Оферта, rental rules, privacy/consent, prohibited categories, support contacts, account-deletion instructions и версии документов | `public`, статический Astro без пользовательских данных и auth | Только публичные versioned документы | Страница не принимает/отражает ПД; старая принятая версия остаётся доступной |
| Operations | Liveness/readiness обязательных зависимостей; при необходимости внутренние metrics | Liveness может быть `public` и минимальным; readiness/metrics — сетевой allowlist/service credential, без secrets | Состояние DB/Redis/providers без credentials, topology и stack trace | Production exposure, утечка env/secret, readiness до DB/migrations |

Ветка KYC, payment scenario и зависящие от них endpoint остаются `BLOCKED`, пока
соответствующий `ACCEPTED` ADR не выбрал ровно один разрешённый вариант.

До появления controller для Payment и Dispute отрицательный e2e создаёт реальные
Payment/Dispute записи и
проверяет, что зарезервированная HTTP-поверхность остаётся закрытой (`404`).
При реализации каждого семейства этот deny-by-default сценарий заменяется
participant/owner/recipient/capability матрицей на фактических endpoint.

Generic `PATCH /:resource/:id/status` для Item, Booking, Payment, Payout и Dispute
запрещён и проверяется e2e. Новый sensitive transition добавляется только
отдельной actor-specific командой с state/ownership preconditions, idempotency и
audit там, где он требуется.

## Известные расхождения, блокирующие безопасный release

Для реализованной item-поверхности расхождений модели ролей и object ownership
не осталось. Будущие participant private-file endpoint остаются deny-by-default
до реализации своих этапов roadmap; owner download для item quarantine реализован.

## Правила сопровождения

- Новый endpoint добавляется в эту матрицу в том же изменении, что controller и
  OpenAPI. Planned-строка заменяется фактическим method/path.
- Изменение доступа требует отрицательного сценария: anonymous, unrelated
  authenticated actor, неправильная роль/capability и неправильное состояние.
- HTTP access/IDOR тесты размещаются в `backend/test/*.e2e-spec.ts` и используют
  настоящие PostgreSQL/PostGIS и Redis. Чистые actor/state rules дополнительно
  тестируются рядом с service.
- Swagger security metadata не заменяет server-side guard и object predicate.
- Presigned URL является краткоживущим bearer capability и учитывается как
  чувствительный ответ, даже если S3 URL находится вне backend router.
