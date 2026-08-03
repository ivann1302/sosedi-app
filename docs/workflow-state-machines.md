# Workflow state machines

Исполняемый канонический контракт находится в
`backend/src/common/domain/workflow-contract.ts`. Таблицы ниже объясняют его, но
не заменяют contract-тест.

## Статусы

| FSM | Статусы |
| --- | --- |
| Booking | `PENDING`, `CONFIRMED`, `ACTIVE`, `RETURNED`, `COMPLETED`, `CANCELLED` |
| Payment | `PENDING`, `SUCCEEDED`, `FAILED`, `CANCELLED` |
| Payout | `PENDING`, `PROCESSING`, `SUCCEEDED`, `FAILED`, `CANCELLED` |
| Dispute | `OPEN`, `UNDER_REVIEW`, `RESOLVED` |

`PAID` не является состоянием Booking. Payment, Payout и Dispute меняются
независимо и не переводят Booking напрямую.

## Переходы

| FSM / command | From → To | Actors | Основные preconditions |
| --- | --- | --- | --- |
| Booking `confirm` | `PENDING → CONFIRMED` | lender | TTL, свободный период, version |
| Booking `cancel` | `PENDING → CANCELLED` | borrower/lender | participant, version |
| Booking `expire` | `PENDING → CANCELLED` | system | TTL, `PENDING_TIMEOUT` |
| Booking `cancel` | `CONFIRMED → CANCELLED` | borrower/lender | participant, cancellation policy |
| Booking `activate` | `CONFIRMED → ACTIVE` | borrower/lender | handover подтверждён обеими сторонами |
| Booking `return` | `ACTIVE → RETURNED` | borrower/lender | возврат подтверждён обеими сторонами |
| Booking `complete` | `RETURNED → COMPLETED` | system | dispute window закрыто, открытого спора нет |
| Payment `succeed` | `PENDING → SUCCEEDED` | provider | событие проверено, сумма/RUB совпадают |
| Payment `fail` | `PENDING → FAILED` | provider | событие проверено |
| Payment `cancel` | `PENDING → CANCELLED` | system/provider | бронь или provider отменили платёж |
| Payout `start` | `PENDING → PROCESSING` | system | возврат, закрытое окно, нет спора, recipient eligible |
| Payout `cancel` | `PENDING → CANCELLED` | system | спор открыт до отправки |
| Payout `succeed/fail` | `PROCESSING → SUCCEEDED/FAILED` | provider | событие проверено |
| Payout `retry` | `FAILED → PROCESSING` | system | новая attempt, нет открытого спора |
| Dispute `review` | `OPEN → UNDER_REVIEW` | dispute admin | capability, step-up, audit |
| Dispute `resolve` | `OPEN/UNDER_REVIEW → RESOLVED` | dispute admin | допустимое решение, step-up, audit |

Payout и Dispute пока не имеют моделей или endpoint. Их enum и таблицы являются
provisional контрактом; создание записей, финансовые последствия и production
provider запрещены до соответствующих ADR/gates.

`CONFIRMED → CANCELLED` также остаётся provisional до versioned cancellation
policy. Исполняемый endpoint сейчас разрешает только `PENDING → CANCELLED`;
no-show/faulty/return incidents создают связанное нефинансовое support
обращение, не меняя FSM.

## Синхронизация

`workflow-contract.spec.ts` блокирует merge, если расходятся:

- Prisma enum;
- backend DTO и OpenAPI schema;
- Dart wire mapping;
- from/to, actors или preconditions канонической таблицы.
