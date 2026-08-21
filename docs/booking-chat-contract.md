# Booking chat contract MVP

Booking является границей единственного диалога: отдельные free-form диалоги,
DM из профиля/карточки Item и поиск пользователей для переписки отсутствуют.
Логический диалог появляется вместе с Booking и имеет тот же `bookingId`; пустой
диалог не требует отдельной строки Conversation.

## Lifecycle

| Booking status | Чтение участниками | User-authored text | System messages |
| --- | --- | --- | --- |
| `PENDING` с живым TTL | да | да, если между участниками нет block | да |
| `CONFIRMED` | да | да, если между участниками нет block | да |
| `ACTIVE` | да | да, если между участниками нет block | да |
| `RETURNED` | да | да до перехода в terminal state, если нет block | да |
| `CANCELLED` | read-only | нет | только уже сохранённые |
| `COMPLETED` | read-only | нет | только уже сохранённые |

Истёкший `PENDING` сначала идемпотентно переводится в `CANCELLED`; отправка по
уже истёкшему TTL запрещена даже до cleanup job. Удаление или блокировка
аккаунта также немедленно закрывают user-authored write. История остаётся
read-only на срок действующего retention/legal-hold; физическое удаление не
должно происходить раньше связанных booking/dispute обязательств.

## Block semantics

Block действует симметрично для чата независимо от того, кто его создал.

- В `PENDING` создание block атомарно отменяет все живые заявки между этой парой
  с отдельной причиной `PARTICIPANT_BLOCKED`, очищает TTL и закрывает write.
  Повторный block не создаёт новые переходы или уведомления.
- В `CONFIRMED`, `ACTIVE` и `RETURNED` block не меняет Booking и не скрывает
  акты/evidence. Он запрещает новые user-authored сообщения в обе стороны;
  системные события и обращение в поддержку остаются доступны.
- Unblock не возобновляет отменённый `PENDING`, но снова разрешает text в всё ещё
  допустимом нетерминальном состоянии другой аренды.

## Privacy and transport

Чат не меняет private access window: телефон, точный адрес и координаты не
публикуются в `PENDING`. Текст сообщения не передаётся в URL, application log,
analytics или push. Inbox/push содержит только opaque `eventId`; содержание
загружается после JWT и повторной participant-проверки. MVP использует REST
refresh/resume/poll и не требует WebSocket.

## HTTP and persistence

- `GET /api/v1/bookings/:bookingId/messages` проверяет participant до cursor и
  возвращает newest page по `(createdAt,id)` с limit 1–100; элементы внутри
  страницы идут хронологически, а `nextCursor` загружает более старую историю.
- `POST /api/v1/bookings/:bookingId/messages` принимает только `body` и UUID v4
  `clientMessageId`. Пара `(authorId,clientMessageId)` уникальна: точный retry
  возвращает прежнее сообщение, другой payload получает
  `409 IDEMPOTENCY_KEY_REUSED`.
- API не возвращает `authorId` второй стороны: автор — только
  `SELF/COUNTERPARTY/SYSTEM`; client ID видит только его автор.
- Фактический send и outbox `BOOKING_MESSAGE_CREATED` одному получателю
  создаются в одной DB transaction. Outbox/inbox/push не хранит body.
- `PATCH /api/v1/bookings/:bookingId/messages/read` после той же participant-
  проверки отмечает прочитанными только уже созданные для actor inbox-события
  чата этой Booking; повторный вызов идемпотентен.
- User text после trim содержит 1–2000 символов; C0/DEL control characters
  запрещены, newline/tab разрешены. DTO whitelist отклоняет attachment/media,
  voice/call/reaction/presence и другие поля вне текстового MVP.
- Под actor/Booking advisory locks считаются только фактически сохранённые
  сообщения за скользящую минуту: максимум 20 на одну Booking и 60 суммарно на
  автора. Точный idempotent retry возвращается до подсчёта и не расходует квоту.
- При физическом удалении User author FK становится `null`, а безопасная
  `BORROWER/LENDER/SYSTEM`-атрибуция и booking retention сохраняются. Self-export
  включает доступную участнику историю без чужих ID/контактов.

## Mobile freshness and system messages

- Экран `/bookings/:bookingId/chat` доступен из деталей Booking. Он хранит draft
  локально, повторяет неуспешную отправку с тем же `clientMessageId`, позволяет
  pull-to-refresh и загружает старую историю по cursor.
- При foreground экран обновляется раз в 15 секунд; при resume приложение
  инвалидирует inbox и открытые message providers. Background polling и
  обязательный WebSocket отсутствуют.
- Unread badge в списке Booking считается по непрочитанным
  `BOOKING_MESSAGE_CREATED` из in-app inbox. Открытие диалога вызывает
  идемпотентный read endpoint. Push остаётся best-effort сигналом только с
  непрозрачным `eventId`; текст загружается из participant API после JWT.
- Backend добавляет `SYSTEM`-сообщения в одной transaction с созданием заявки,
  confirm/автоотменой конкурентов, ручной отменой, timeout, передачей и возвратом.
  Они не имеют `clientMessageId` и не создают отдельный пользовательский
  `BOOKING_MESSAGE_CREATED`, поэтому не маскируются под входящий текст.

## Report, block and operator access

- `MESSAGE` report разрешён участнику только на user-authored сообщение второй
  стороны в его Booking. Собственный и `SYSTEM` text, а также чужая Booking
  возвращают нераскрывающий `404`. Доступны только target-specific причины
  harassment/privacy/fraud/other; общий лимит и 24-часовой dedup не меняются.
- В mobile у каждого `COUNTERPARTY` message есть отдельное действие
  «Пожаловаться», а в chat header — отдельная подтверждаемая блокировка. Endpoint
  сам выводит counterparty из participant Booking и не доверяет user ID клиента.
- Pair-block сериализуется на пару пользователей. Он атомарно отменяет все живые
  `PENDING` этой пары с причиной `PARTICIPANT_BLOCKED`, одним system message,
  transition и outbox на Booking; повтор не дублирует их. `CONFIRMED/ACTIVE/
  RETURNED`, acts/evidence и системная история не меняются, но user text закрыт
  в обе стороны. Unblock не восстанавливает отменённую заявку.
- Очередь MODERATION содержит для `MESSAGE` только metadata. Текст открывается
  лишь по конкретной жалобе через отдельный endpoint; каждое чтение пишет
  `REPORTED_BOOKING_MESSAGE_ACCESSED` с report/booking/request context, но без
  body. Решение может dismiss report либо применить существующий global block к
  автору только при отсутствии незавершённых аренд.
- SUPPORT не получает произвольный поиск чатов. До 100 последних сообщений
  доступны только из `GENERAL` support ticket с `bookingId`, хронологически и без
  user IDs/client IDs. Каждое чтение пишет `SUPPORT_BOOKING_CHAT_ACCESSED` без
  текста; capability `SUPPORT` и `MODERATION` не взаимозаменяемы.

Retention утверждён принятой baseline-policy ADR-0002: text/system timestamps
хранятся как часть Booking 3 года после завершения/отмены или закрытия связанной
претензии — что позже; scoped legal hold имеет приоритет. До public release срок
и основание проходят обязательный RF legal/privacy review.
