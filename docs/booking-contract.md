# Booking contract MVP

Статусы Booking независимы от Payment/Payout/Dispute. Mobile при создании
передаёт `itemId`, `startDate`, `endDate`, две показанные версии документов и
два явных acceptance-флага. Lender, ставка, сумма, статус, TTL, actor,
server timestamp и метод `BOOKING_SUBMIT_CHECKBOX` всегда назначаются backend.
Client versions обязаны точно совпасть с approved runtime versions; отсутствие
или stale acceptance даёт `409 BOOKING_TERMS_ACCEPTANCE_REQUIRED` до DB.

Mobile flow выводится из четырёх compile-time значений:
`MARKETPLACE_OFFER_VERSION`, `MARKETPLACE_OFFER_URL`,
`MARKETPLACE_CANCELLATION_POLICY_VERSION` и
`MARKETPLACE_RENTAL_RULES_URL`. Default/неполный/draft/http/version-mismatch
config оставляет submit выключенным. При валидном config mobile показывает две
HTTPS-ссылки и требует два независимых checkbox; availability должна быть
`true`. Повтор неоднозначного запроса с тем же payload использует тот же UUID v4,
а изменение дат или версии создаёт новый request ID.
Общий mobile documents config дополнительно принимает versioned
`MARKETPLACE_PRIVACY_VERSION`/`MARKETPLACE_PRIVACY_URL`: профиль показывает
offer/rules/privacy только полным опубликованным набором и никогда не выдаёт
draft за действующий документ.

`POST /bookings` по умолчанию закрыт и до обращения к БД возвращает
`503 BOOKING_LEGAL_GATE_CLOSED`. Создание разрешается только при двух
утверждённых недрафтовых версиях в `MARKETPLACE_OFFER_VERSION` и
`MARKETPLACE_CANCELLATION_POLICY_VERSION`; release gate отдельно проверяет их
production URL/evidence. Пустая или содержащая `draft` версия не включает flow.

## Calendar

- `startDate`/`endDate` — локальные календарные даты `Europe/Moscow` в формате
  `YYYY-MM-DD`, в PostgreSQL хранятся как `date`.
- Обе границы включены; одинаковые даты означают один день.
- Начало не раньше текущей московской даты, период 1–30 дней, начало не дальше
  90 дней.
- Один Item представляет одну физическую единицу; inventory quantity/pool в MVP
  отсутствуют.

## State transitions

| Command | From | To | Actor | Required preconditions |
|---|---|---|---|---|
| create | — | `PENDING` | borrower | active borrower/lender, `APPROVED` Item, not self, free inclusive period |
| confirm | `PENDING` | `CONFIRMED` | lender | not expired, period still reserved, version matches |
| cancel | `PENDING` | `CANCELLED` | borrower/lender | participant, live TTL |
| expire | `PENDING` | `CANCELLED` | system | `expiresAt <= now`, reason `PENDING_TIMEOUT` |
| activate | `CONFIRMED` | `ACTIVE` | both participants | handover confirmed by both |
| return | `ACTIVE` | `RETURNED` | both participants | return confirmed by both |
| complete | `RETURNED` | `COMPLETED` | system | dispute window closed, no open dispute |

Любой другой переход запрещён. Запрещённая команда не меняет Booking/history.
Подтверждение выполняется под locks Booking и Item. Ровно одна заявка становится
`CONFIRMED`; другие живые пересекающиеся `PENDING` атомарно переходят в
`CANCELLED` с `cancellationReason=COMPETING_REQUEST_CONFIRMED`.

`POST /bookings/:id/cancel` сейчас исполняет только безопасную до-legal часть
матрицы: borrower переводит живой `PENDING` в `CANCELLED` с
`BORROWER_CANCELLED`, lender — с `LENDER_DECLINED`. Повтор той же стороны
идемпотентен, history/outbox остаются единичными, календарь освобождается.
`CONFIRMED` cancellation отклоняется до утверждения versioned cancellation
policy; backend не выдумывает refund, fee или штраф.

## Reservation

`PENDING` резервирует пересекающийся период на 15 минут. Создание выполняется в
транзакции PostgreSQL с advisory transaction lock сначала по
`borrowerId`, затем по `itemId`; под lock проверяются лимит, Item/owner/price и
пересечения, затем создаётся Booking. Один borrower может одновременно иметь не
более 5 неистёкших `PENDING`. Истёкший `PENDING` не блокирует новую заявку и
идемпотентный cleanup не реже раза в минуту переводит его в `CANCELLED` с
`cancellationReason=PENDING_TIMEOUT`. Отдельного статуса `EXPIRED` нет.

Владелец может добавить интервал недоступности длиной 1–30 дней в пределах
90-дневного горизонта. Создание/удаление интервала и создание Booking используют
один advisory lock по `itemId`: новый интервал отклоняется при пересечении с
живой бронью, а новая бронь — при пересечении с интервалом. Существующая бронь
при изменении календаря никогда не отменяется.

Цена: число календарных дней × server `pricePerDay`, валюта RUB. Payment status
не входит в Booking FSM; production payment flow остаётся закрыт provider/legal
gate.

До отправки заявки borrower видит ставку × число дней, отсутствие залога,
комиссию Sosedi `0`, выплату владельцу, оплату при передаче, итог и RUB. Lender
видит тот же immutable breakdown в `PENDING` до подтверждения. Legacy Item с
ненулевым залогом получает `ITEM_DEPOSIT_NOT_SUPPORTED` до отдельного
deposit/legal gate и не создаёт нечитаемый Booking snapshot.

Новый Booking хранит immutable JSON snapshot названия/владельца Item, ставки,
числа дней, rental subtotal, отсутствующего либо заданного залога, нулевой
platform fee пилота, owner payout, total, RUB, `PAY_ON_HANDOVER`, handover point
и версии Item. В этом сценарии Booking не создаёт Payment, payout или online
receipt и не получает ложный статус `PAID`; mobile до заявки явно показывает
оплату при передаче, комиссию Sosedi 0 ₽ и отсутствие приёма/перевода денег
платформой.
Новые Booking всегда получают настроенные `offerVersion` и
`cancellationPolicyVersion`; без них endpoint закрыт. Nullable reading
сохраняется только для совместимости с provisional/legacy snapshots.
Тот же immutable JSON содержит acceptance evidence: borrower ID, server
timestamp, фиксированный UI method и обе версии. Поля DTO optional только для
того, чтобы закрытый legal gate стабильно отвечал `503` до DB; при открытом gate
service обязательно требует их и не доверяет client timestamp/method.
До provider ADR `PaymentsModule` не имеет HTTP controller или payout/split
service: fake provider доступен только внутренним доменным тестам. Ручная
выплата владельцу со счёта Sosedi не является скрытым fallback.

`GET /bookings` и `GET /bookings/:id` доступны только borrower/lender. Pricing
snapshot виден участникам во всех состояниях, но точный handover address и
контакт второй стороны до утверждения dispute window возвращаются только в
`CONFIRMED/ACTIVE`. `PENDING/RETURNED/CANCELLED/COMPLETED` получают `null`;
после возврата участники сохраняют условия и акты, но не точный адрес/контакт.
Mobile инвалидирует уже загруженные private booking details при уходе приложения
в background и получает решение заново от backend. Публичный Item API по-прежнему
содержит только coarse location.

## Handover acts

Участник `CONFIRMED` создаёт единственный `HANDOVER` act, а участник `ACTIVE` —
единственный `RETURN` act. Act включает server author/time и private evidence,
привязанное к одноразовому upload intent; backend повторно проверяет bucket/key,
MIME/magic bytes, безопасно перекодирует изображение без metadata/вредоносного
хвоста и сохраняет SHA-256 очищенных байтов. Только второй участник может
подтвердить act. Подтверждение атомарно переводит Booking соответственно в
`ACTIVE` или `RETURNED` и пишет outbox event. Evidence выдаётся только
participant через короткий presigned download URL.

Каждый фактический переход пишет `BookingTransitionHistory` в своей транзакции:
actor/actor type, command, old/new status, reason, requestId и server timestamp.
PostgreSQL trigger запрещает UPDATE/DELETE history; отклонённая команда не
создаёт запись.

Extension в MVP не поддерживается. `POST /bookings/:id/extend` сначала
проверяет participant boundary, затем всегда возвращает
`409 BOOKING_EXTENSION_NOT_SUPPORTED`; Booking и history не меняются.

## Manual booking issues

До dispute/payment/legal gate no-show и проблемы возврата не меняют Booking или
деньги автоматически. Участник создаёт `GENERAL` support ticket с обязательной
парой `bookingId + bookingIssueReason`; backend повторно проверяет participant,
actor, состояние и московскую календарную дату.

| Reason | Кто может сообщить | Допустимое состояние/дата | Автоматический эффект |
| --- | --- | --- | --- |
| `OWNER_NO_SHOW` | borrower | `CONFIRMED`, не раньше `startDate` | Только связанное обращение |
| `BORROWER_NO_SHOW` | lender | `CONFIRMED`, не раньше `startDate` | Только связанное обращение |
| `ITEM_FAULTY` | borrower | `CONFIRMED`, не раньше `startDate` | Только связанное обращение |
| `EARLY_RETURN` | participant | `ACTIVE`, до `endDate` | Только связанное обращение |
| `LATE_RETURN` | participant | `ACTIVE`, после `endDate` | Только связанное обращение |
| `ITEM_DAMAGED` / `ITEM_LOST` | participant | `ACTIVE` или `RETURNED` | Только связанное обращение |

Обычный `RETURN` act и подтверждение второй стороной остаются обязательными.
Support не обещает refund/payout/fee и не переводит Booking в `COMPLETED`;
финансовое решение появится только после утверждённого dispute flow.

## Events and inbox

Booking, support и moderation пишут `NotificationOutboxEvent` в той же
DB-транзакции, что и доменное изменение. Poller создаёт inbox-записи получателей
с уникальным `(eventId, recipientId)`, атомарно создаёт durable push-delivery
задачи для их актуальных device token и только затем помечает outbox
обработанным. Повторный запуск безопасен.
PostgreSQL e2e принудительно обрывает worker перед `processedAt`: транзакция
откатывает промежуточные inbox/push rows, durable outbox остаётся pending, а
повтор после восстановления создаёт единственные записи и не создаёт Payment.
Триггеры `BOOKING_CONFIRMED`, `ITEM_APPROVED/ITEM_REJECTED` и
`SUPPORT_REPLIED` используют этот же путь; delivery processor передаёт
`PushProvider` только token и opaque `eventId`. До подключения credential-gated
адаптера disabled provider оставляет задачу в bounded retry, а inbox остаётся
источником истины.

Список inbox содержит только opaque `eventId`, тип, минимальный entity ID,
timestamps и read state. Детали загружаются отдельным авторизованным запросом
после повторной participant/owner-проверки. Push provider получает только token
и opaque `eventId`; адрес, контакт, телефон, сумма, текст и JWT туда не входят.
