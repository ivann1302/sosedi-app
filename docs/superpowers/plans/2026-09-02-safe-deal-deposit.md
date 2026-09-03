# Safe Deal Deposit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Добавить полностью серверный, но строго local/staging-only сценарий `FAKE_SAFE_DEAL` с необязательным залогом, одним тестовым checkout, автоматическим возвратом, финансовым спором, operator resolution и мобильным UX, не включая production-платежи.

**Architecture:** `PAY_ON_HANDOVER` остаётся текущим production-safe режимом и по-прежнему запрещает ненулевой залог. Новый `PaymentPolicyService` включает `FAKE_SAFE_DEAL` только при полном наборе явных non-production env. `Booking`, `Payment`, `BookingDeposit` и `FinancialDispute` имеют независимые состояния; денежные команды записываются как идемпотентные `DepositOperation`, а worker применяет результат fake provider после повторной проверки состояния. Mobile получает узкий server-derived policy, operator использует существующую MFA admin-session и capabilities.

**Tech Stack:** NestJS 11, TypeScript, Prisma/PostgreSQL, Jest/Supertest, Flutter/Riverpod/Dio/Freezed, React/Vite operator UI.

**Spec:** [`docs/superpowers/specs/2026-09-02-safe-deal-deposit-design.md`](../specs/2026-09-02-safe-deal-deposit-design.md)

## Global Constraints

- Production money movement remains disabled until ADR-0005 or its successor is `ACCEPTED` and the provider/legal/accounting/KYC gates are closed.
- `FAKE_SAFE_DEAL` must fail startup in `production`; incomplete `SAFE_DEAL` must fail startup in every environment.
- Do not add a live YooKassa adapter, generic ledger, wallet, generic feature flags, payout model or provider plugin architecture.
- Use integer kopecks for every new policy, command and resolution API. Existing legacy Item/Booking response numbers remain only for backward compatibility.
- Never let a payment/deposit provider result directly change Booking state. A local command/worker must lock and re-check every cross-aggregate precondition.
- Do not touch the user's current unrelated changes in `mobile/integration_test/app_smoke_test.dart`, `mobile/lib/features/catalog/presentation/catalog_screen.dart`, `mobile/test/features/catalog/catalog_screen_test.dart` or `docs/APP_WORKFLOW_GUIDE.md`.
- Follow TDD: add one business/security test, observe the expected failure, add the minimum implementation, then run the relevant `make` verification.
- After every task inspect `git diff --check` and commit only that task's files. Do not stage unrelated worktree changes.
- No checklist checkbox is closed by this pre-provider slice. Update only factual `DOING` notes and the synchronized roadmap; leave `.codex/HANDOFF.md` unchanged unless a checklist item is genuinely completed.

---

## File Map

### Backend policy and environment boundary

- Create `backend/src/payments/payment-policy.service.ts` — parse and expose the only active payment scenario.
- Create `backend/src/payments/payment-policy.service.spec.ts` — fail-closed policy tests.
- Create `backend/src/payments/marketplace-policy.controller.ts` — public read-only policy endpoint.
- Create `backend/src/payments/dto/marketplace-policy-response.dto.ts` — exact mobile contract.
- Modify `backend/src/payments/payments.module.ts` — register/export policy and controller.
- Modify `backend/.env.example`, `ops/environments/local.env.example`, `ops/environments/staging.env.example`, `ops/environments/production.env.example` — replace the unused provider-mode naming with the explicit scenario and fake-policy values.
- Modify `scripts/environment-isolation.mjs`, `scripts/environment-isolation.test.mjs`, `scripts/verify-release-gates.mjs`, `scripts/verify-release-gates.test.mjs` — production/static fail-closed checks.

### Persistent domain and exact money

- Modify `backend/prisma/schema.prisma` — `BookingDeposit`, `DepositOperation`, `FinancialDispute`, `DisputeEvidence`, enums, relations and `DISPUTE` capability.
- Create `backend/prisma/migrations/20260902000100_add_safe_deal_deposit_domain/migration.sql` — tables, indexes and money/state constraints.
- Create `backend/src/payments/money-minor.ts` and `backend/src/payments/money-minor.spec.ts` — exact Decimal/minor conversion.
- Create `backend/src/payments/deposit-state.ts` and `backend/src/payments/deposit-state.spec.ts` — allowed lifecycle and resolution invariant.
- Modify `backend/src/payments/safe-deal-price.ts` and `backend/src/payments/safe-deal-price.spec.ts` — rental plus deposit checkout total without adding deposit to owner payout.
- Create `backend/test/money-constraints.e2e-spec.ts` — direct database constraint coverage.

### Item and Booking integration

- Modify `backend/src/items/dto/create-item.dto.ts`, `backend/src/items/items.service.ts`, `backend/src/items/items.module.ts` — exact deposit input plus policy enforcement.
- Modify `backend/src/items/items.service.spec.ts`, `backend/src/items/items.openapi.spec.ts`, `backend/test/items.e2e-spec.ts` — zero/disabled/max/direct-write tests.
- Modify `backend/src/booking/booking-terms.ts`, `backend/src/booking/booking-terms.spec.ts` — immutable policy and exact-money snapshot.
- Modify `backend/src/booking/booking.service.ts`, `backend/src/booking/booking.service.spec.ts`, `backend/src/booking/booking.module.ts` — create/read deposit aggregate and preserve offline behavior.
- Modify `backend/src/booking/dto/participant-booking-response.dto.ts` — payment/deposit participant summary.
- Modify `backend/test/booking.e2e-spec.ts` — offline fail-closed regression.
- Create `backend/test/fake-safe-deal.e2e-spec.ts` — one isolated end-to-end fake flow suite.

### Fake checkout, lifecycle worker and cancellation

- Replace `backend/src/payments/fake-payment.provider.ts` with `backend/src/payments/fake-safe-deal.provider.ts` and replace its spec — deterministic success/decline/timeout plus operation outcomes.
- Create `backend/src/payments/fake-safe-deal.controller.ts` and `backend/src/payments/dto/fake-checkout.dto.ts` — non-production test checkout command.
- Create `backend/src/payments/deposit.service.ts` and `backend/src/payments/deposit.service.spec.ts` — checkout hold, cancellation, deadline, resolution and retry commands.
- Create `backend/src/payments/deposit-deadline.service.ts` and its spec — due-deposit scan.
- Create `backend/src/payments/deposit-operation.processor.ts` and its spec — idempotent provider operation execution.
- Modify `backend/src/booking/booking-act.service.ts` and its spec — require held funds before handover and snapshot deadline after return.
- Modify `backend/src/booking/booking-expiry.service.ts` and its spec — cancel an unheld deposit with an expired pending Booking.

### Financial dispute and private evidence

- Create `backend/src/payments/dispute.service.ts` and `backend/src/payments/dispute.service.spec.ts` — participant open/evidence/read and admin resolution.
- Create `backend/src/payments/dispute.controller.ts`, `backend/src/payments/admin-dispute.controller.ts` — participant and capability-gated endpoints.
- Create `backend/src/payments/dto/create-dispute.dto.ts`, `add-dispute-evidence.dto.ts`, `resolve-dispute.dto.ts`, `dispute-response.dto.ts` — strict request/response contracts.
- Modify `backend/src/upload/upload.types.ts`, `backend/src/upload/dto/request-upload-url.dto.ts`, `backend/src/upload/upload.service.ts`, `backend/src/upload/upload.service.spec.ts` — `DISPUTE_EVIDENCE` path through the existing private-image pipeline.
- Modify `backend/src/admin/first-admin-bootstrap.ts` and its spec — allow the owner to bootstrap explicit `DISPUTE` and `FINANCE` capabilities while a manager can remain `SUPPORT`-only.
- Create `backend/src/admin/admin-any-capability.decorator.ts` and modify `backend/src/admin/admin-session.guard.ts` — audited admin read access for `SUPPORT` or `DISPUTE`, without weakening all-of checks on financial commands.
- Modify `backend/test/admin-session.e2e-spec.ts` and `backend/test/fake-safe-deal.e2e-spec.ts` — support-only, finance, stale-session, outsider and race boundaries.

### Operator UI

- Modify `operator/src/api.ts` — dispute queue/evidence/resolve/retry API.
- Modify `operator/src/App.tsx` — support read-only queue and finance decision controls.
- Modify `operator/src/styles.css` — minimal amount/status layout.
- Modify `operator/README.md` — exact capabilities and fake-only limitation.

### Mobile policy, listing and booking UX

- Create `mobile/lib/features/payments/data/marketplace_policy_models.dart`, `marketplace_policy_models.freezed.dart`, `marketplace_policy_models.g.dart` and `marketplace_policy_service.dart` — server policy provider.
- Create `mobile/test/features/payments/marketplace_policy_service_test.dart` — response and failure contract.
- Modify `mobile/lib/features/item/data/create_item_models.dart`, `create_item_models.freezed.dart`, `create_item_models.g.dart`, `owned_item_models.dart`, `owned_item_models.freezed.dart`, `owned_item_models.g.dart` — optional `depositAmountMinor` commands.
- Modify `mobile/lib/features/item/presentation/create_item_screen.dart`, `edit_item_screen.dart` — policy-gated `Без залога / С залогом` form.
- Modify `mobile/test/features/item/create_item_service_test.dart`, `create_item_screen_test.dart`, `owned_items_service_test.dart`, `edit_item_screen_test.dart` — request and visibility tests.
- Modify `mobile/lib/features/booking/data/booking_models.dart`, `booking_models.freezed.dart`, `booking_models.g.dart`, `booking_service.dart` — payment/deposit/dispute contracts.
- Modify `mobile/lib/features/booking/presentation/booking_create_screen.dart`, `booking_details_screen.dart` — exact breakdown, server-backed fake checkout, deposit status/deadline and dispute action.
- Modify `mobile/lib/features/booking/domain/booking_action_controller.dart` — commands and provider invalidation.
- Delete `mobile/lib/features/booking/domain/demo_payment_controller.dart` and remove its local-state assertions from `booking_screens_test.dart` after the server-backed flow passes.
- Modify `mobile/test/features/booking/booking_service_test.dart`, `booking_screens_test.dart` — server-backed behavior.

### Source-of-truth documentation

- Modify `docs/adr/0005-monetized-safe-deal-provider.md` — record that only gated fake schema/API is now implemented; keep status `PROPOSED`.
- Modify `MVP_CHECKLIST.md` and `sosedi-roadmap.html` in the same task — matching factual pre-provider `DOING` notes without changing completion percentage.

---

## Task 1: Add the explicit payment policy and production fail-closed boundary

**Files:**

- Create: `backend/src/payments/payment-policy.service.ts`
- Create: `backend/src/payments/payment-policy.service.spec.ts`
- Create: `backend/src/payments/marketplace-policy.controller.ts`
- Create: `backend/src/payments/dto/marketplace-policy-response.dto.ts`
- Modify: `backend/src/payments/payments.module.ts`
- Modify: `backend/.env.example`
- Modify: `ops/environments/local.env.example`
- Modify: `ops/environments/staging.env.example`
- Modify: `ops/environments/production.env.example`
- Modify: `scripts/environment-isolation.mjs`
- Modify: `scripts/environment-isolation.test.mjs`
- Modify: `scripts/verify-release-gates.mjs`
- Modify: `scripts/verify-release-gates.test.mjs`

- [ ] Write `payment-policy.service.spec.ts` for these exact cases: default `PAY_ON_HANDOVER`; complete fake policy accepted in `development`/`staging`/`test`; fake rejected in `production`; partial fake config rejected; zero/unsafe maximum rejected; `SAFE_DEAL` rejected with `SAFE_DEAL_PROVIDER_NOT_CONFIGURED`.
- [ ] Run `make backend-test` and confirm the new spec fails because the service does not exist.
- [ ] Implement this public shape and keep raw strings inside the parser:

```ts
export enum PaymentScenario {
  PAY_ON_HANDOVER = 'PAY_ON_HANDOVER',
  FAKE_SAFE_DEAL = 'FAKE_SAFE_DEAL',
  SAFE_DEAL = 'SAFE_DEAL',
}

export type MarketplacePolicy = {
  paymentScenario: PaymentScenario;
  deposit: {
    enabled: boolean;
    currency: 'RUB';
    maximumMinor: number | null;
    policyVersion: string | null;
    disputeWindowSeconds: number | null;
  };
};
```

- [ ] Make `PaymentPolicyService` implement `OnModuleInit`, parse once, expose `current()`, `requireFakeSafeDeal()` and `assertDepositAllowed(amountMinor: bigint)`, and never invent a maximum, policy version or duration.
- [ ] Add `GET /api/v1/marketplace-policy` returning the exact `MarketplacePolicy` envelope without auth or secrets.
- [ ] Replace `PAYMENT_PROVIDER_MODE` in environment examples and isolation scripts with:

```dotenv
PAYMENT_SCENARIO="FAKE_SAFE_DEAL"
FAKE_SAFE_DEAL_DEPOSIT_MAX_MINOR="10000000"
FAKE_SAFE_DEAL_POLICY_VERSION="fake-deposit-2026-09-02"
FAKE_SAFE_DEAL_DISPUTE_WINDOW_SECONDS="300"
```

  Local/staging examples use those explicit test values. Production uses only `PAYMENT_SCENARIO="PAY_ON_HANDOVER"` and contains none of the fake-policy keys.
- [ ] Update the release gate so a production artifact accepts only `PAY_ON_HANDOVER` while ADR-0005 is not accepted; add node tests proving `FAKE_SAFE_DEAL` and `SAFE_DEAL` fail.
- [ ] Run `make backend-test`, `make environment-isolation-test`, `make release-gates-test`, `make backend-build` and `git diff --check`.
- [ ] Commit only Task 1 files:

```bash
git commit -m "feat(payments): add fail-closed marketplace policy"
```

## Task 2: Persist the minimal deposit and dispute aggregates

**Files:**

- Modify: `backend/prisma/schema.prisma`
- Create: `backend/prisma/migrations/20260902000100_add_safe_deal_deposit_domain/migration.sql`
- Create: `backend/src/payments/money-minor.ts`
- Create: `backend/src/payments/money-minor.spec.ts`
- Create: `backend/src/payments/deposit-state.ts`
- Create: `backend/src/payments/deposit-state.spec.ts`
- Modify: `backend/src/payments/safe-deal-price.ts`
- Modify: `backend/src/payments/safe-deal-price.spec.ts`
- Create: `backend/test/money-constraints.e2e-spec.ts`

- [ ] Add failing unit tests for Decimal `10.01` ↔ `1001n`, rejection of fractional kopecks/unsafe JSON minor values, legal deposit transitions, and `refundMinor + releaseMinor === depositMinor`.
- [ ] Extend the price test with rental `10_000n`, deposit `5_000n`, fee `100n`, borrower total `15_000n`, owner payout `9_900n`; assert the deposit never enters fee or normal owner payout.
- [ ] Run `make backend-test` and confirm the new money/state assertions fail.
- [ ] Add exact conversion helpers:

```ts
export function decimalToMinor(value: Prisma.Decimal): bigint;
export function minorToDecimal(value: bigint): Prisma.Decimal;
export function minorToSafeNumber(value: bigint): number;
export function assertResolutionTotal(
  depositMinor: bigint,
  refundMinor: bigint,
  releaseMinor: bigint,
): void;
```

- [ ] Add Prisma enums `DepositStatus`, `DepositOperationKind`, `DepositOperationStatus`, `FinancialDisputeReason`; reuse the existing `DisputeStatus` enum; add `DISPUTE` to `AdminCapability`.
- [ ] Add these aggregate relations and no generalized accounting tables:

```prisma
model BookingDeposit {
  id                       String        @id @default(uuid())
  bookingId                String        @unique
  amount                   Decimal       @db.Decimal(10, 2)
  currency                 String        @default("RUB")
  policyVersion            String
  disputeWindowSeconds     Int
  status                   DepositStatus @default(PENDING)
  disputeWindowEndsAt      DateTime?
  refundedAmount           Decimal       @default(0) @db.Decimal(10, 2)
  releasedToLenderAmount   Decimal       @default(0) @db.Decimal(10, 2)
  createdAt                DateTime      @default(now())
  updatedAt                DateTime      @updatedAt
  booking                  Booking       @relation(fields: [bookingId], references: [id], onDelete: Restrict)
  operations               DepositOperation[]

  @@index([status, disputeWindowEndsAt])
  @@map("booking_deposits")
}
```

- [ ] Define `DepositOperation` with unique `idempotencyKey`, nullable unique `providerOperationId`, self-relation `retryOfId`, exact amount, kind/status/error code/timestamps, `attempts`, `nextAttemptAt` and nullable `processingUntil` lease. Define one `FinancialDispute` per Booking with opener/resolver, reason/description, decision reason, refund/release amounts and timestamps. Define `DisputeEvidence` with unique `uploadIntentId`, storage key and hash.
- [ ] In the SQL migration replace `items_deposit_pilot_check` with a broad storage constraint (`NULL` or `0..30_000_000` RUB) while application policy remains stricter. Add checks for RUB, positive deposit amount, positive operation amount, non-negative resolved amounts, sum not exceeding deposit, and exact equality in `RESOLVED`.
- [ ] Add direct Prisma e2e writes proving the database rejects negative/excess/resolved-mismatch values.
- [ ] Run `make backend-prisma-generate`, `make backend-test`, `make backend-test-e2e` and `git diff --check`.
- [ ] Commit only Task 2 files:

```bash
git commit -m "feat(payments): add deposit and dispute domain"
```

## Task 3: Gate Item deposits and snapshot them into Booking

**Files:**

- Modify: `backend/src/items/dto/create-item.dto.ts`
- Modify: `backend/src/items/items.service.ts`
- Modify: `backend/src/items/items.module.ts`
- Modify: `backend/src/items/items.service.spec.ts`
- Modify: `backend/src/items/items.openapi.spec.ts`
- Modify: `backend/test/items.e2e-spec.ts`
- Modify: `backend/src/booking/booking-terms.ts`
- Modify: `backend/src/booking/booking-terms.spec.ts`
- Modify: `backend/src/booking/booking.service.ts`
- Modify: `backend/src/booking/booking.service.spec.ts`
- Modify: `backend/src/booking/booking.module.ts`
- Modify: `backend/src/booking/dto/participant-booking-response.dto.ts`
- Modify: `backend/test/booking.e2e-spec.ts`
- Create: `backend/test/fake-safe-deal.e2e-spec.ts`

- [ ] Add failing Item service/OpenAPI tests for `depositAmountMinor`: omitted/zero accepted offline; non-zero rejected offline; fake amount at maximum accepted; amount above maximum rejected; legacy `depositAmount` remains accepted only as `null`/`0`; sending both fields is rejected.
- [ ] Add failing Booking tests for exact snapshot, `BookingDeposit(PENDING)` creation under fake policy, no aggregate under offline policy, and legacy non-zero Item fail-closed under offline policy.
- [ ] Run `make backend-test` and confirm the new tests fail for missing integration.
- [ ] Add `depositAmountMinor?: number | null` with `@IsInt()`, `@Min(0)`, `@Max(3_000_000_000)` to Item create/update input. Keep legacy `depositAmount` constrained to `0` only and reject requests containing both fields.
- [ ] Inject `PaymentPolicyService` into `ItemsService`; convert minor units once with `minorToDecimal`; call `assertDepositAllowed` on create and whenever update explicitly carries a deposit command.
- [ ] Extend `BookingTermsSnapshot` with exact values while retaining existing decimal response fields:

```ts
type BookingMoneyMinor = {
  pricePerDay: number;
  rentalSubtotal: number;
  deposit: number;
  platformFee: number;
  ownerPayout: number;
  total: number;
};

type DepositTerms = {
  policyVersion: string;
  disputeWindowSeconds: number;
} | null;
```

  `PAY_ON_HANDOVER` snapshots have `depositTerms: null`, deposit minor `0`, fee `0` and unchanged totals. `FAKE_SAFE_DEAL` snapshots copy the current policy version/window and Item deposit exactly.
- [ ] Make the snapshot reader accept old valid offline snapshots and require the new exact fields for `FAKE_SAFE_DEAL`. It must verify lender/borrower binding, `rental + deposit = total`, and deposit terms matching a positive deposit.
- [ ] In one Booking transaction create `BookingDeposit(PENDING)` only when snapshotted deposit minor is positive. Store `Booking.totalAmount` as the one-checkout total in fake mode and unchanged rental total offline.
- [ ] Include `payment` and `deposit` in participant queries and expose:

```ts
type ParticipantDeposit = {
  amountMinor: number;
  status: DepositStatus;
  refundedMinor: number;
  releasedToLenderMinor: number;
  policyVersion: string;
  disputeWindowEndsAt: Date | null;
};

type ParticipantPayment = {
  amountMinor: number;
  status: PaymentStatus;
} | null;
```

- [ ] Keep exact address/contact visibility unchanged; this task must not broaden `HANDOVER_VISIBLE_STATUSES`.
- [ ] Add `fake-safe-deal.e2e-spec.ts` setup that starts the app with complete fake env and restores all modified `process.env` keys in `afterAll`. Keep the existing e2e setup default offline.
- [ ] Run `make backend-prisma-generate`, `make backend-test`, `make backend-test-e2e`, `make backend-build` and `git diff --check`.
- [ ] Commit only Task 3 files:

```bash
git commit -m "feat(booking): snapshot policy-gated deposits"
```

## Task 4: Replace the local-only payment card with a server-backed fake checkout

**Files:**

- Delete: `backend/src/payments/fake-payment.provider.ts`
- Delete: `backend/src/payments/fake-payment.provider.spec.ts`
- Create: `backend/src/payments/fake-safe-deal.provider.ts`
- Create: `backend/src/payments/fake-safe-deal.provider.spec.ts`
- Create: `backend/src/payments/fake-safe-deal.controller.ts`
- Create: `backend/src/payments/dto/fake-checkout.dto.ts`
- Create: `backend/src/payments/deposit.service.ts`
- Create: `backend/src/payments/deposit.service.spec.ts`
- Modify: `backend/src/payments/payments.module.ts`
- Modify: `backend/src/booking/booking.service.ts`
- Modify: `backend/src/booking/booking-expiry.service.ts`
- Modify: `backend/src/booking/booking-expiry.service.spec.ts`
- Modify: `backend/test/fake-safe-deal.e2e-spec.ts`

- [ ] Add failing provider tests for stable idempotency IDs, conflicting reuse, and deterministic `SUCCESS`, `DECLINE`, `TIMEOUT`. Add e2e tests that fake routes return non-disclosing `404` in offline mode.
- [ ] Add failing service/e2e tests proving only the borrower of a `CONFIRMED` Booking can checkout, decline/timeout create no successful Payment or hold, retry after decline can succeed, duplicate success creates one Payment and one HOLD operation, and Booking remains `CONFIRMED`.
- [ ] Run `make backend-test` and confirm the replacement tests fail.
- [ ] Keep the fake provider request/result contract narrow and local to `fake-safe-deal.provider.ts`:

```ts
export type ProviderOperationResult =
  | { outcome: 'SUCCEEDED'; providerOperationId: string }
  | { outcome: 'DECLINED'; errorCode: string }
  | { outcome: 'TIMEOUT' };

export class FakeSafeDealProvider {
  checkout(request: FakeCheckoutRequest): Promise<ProviderOperationResult>;
  executeDepositOperation(request: FakeDepositOperationRequest): Promise<ProviderOperationResult>;
}
```

- [ ] Inject the single fake implementation directly; do not add an interface token or provider factory before a second accepted implementation exists. `PaymentPolicyService.requireFakeSafeDeal()` must run before any fake command.
- [ ] Add `POST /api/v1/dev/fake-safe-deal/bookings/:bookingId/checkout` with DTO enum `SUCCESS | DECLINE | TIMEOUT` and required `Idempotency-Key`. Return `404` unless fake mode is active.
- [ ] On `SUCCESS`, lock Booking, re-check borrower/status/snapshot/amount, and atomically create or return the single successful `Payment`. If a deposit exists, mark `BookingDeposit` `HELD` and append one successful HOLD operation; a no-deposit fake checkout creates neither. Store no raw payload and no fake checkout URL.
- [ ] On `DECLINE` or `TIMEOUT`, return the deterministic response without creating a successful Payment, changing Booking or claiming the deposit is held.
- [ ] Extend fake-only pre-handover cancellation: `CONFIRMED` plus `PENDING` deposit becomes `CANCELLED`; `CONFIRMED` plus `HELD` deposit becomes `RESOLVING` with one full REFUND operation. Preserve the current offline rule that only `PENDING` can be cancelled.
- [ ] When a pending Booking expires or loses to a competing confirmation, mark its unheld deposit `CANCELLED` in the same transaction.
- [ ] Run `make backend-test`, `make backend-test-e2e`, `make backend-build` and `git diff --check`.
- [ ] Commit only Task 4 files:

```bash
git commit -m "feat(payments): add server-backed fake checkout"
```

## Task 5: Process return deadlines, refunds and Booking completion

**Files:**

- Modify: `backend/src/payments/deposit.service.ts`
- Modify: `backend/src/payments/deposit.service.spec.ts`
- Create: `backend/src/payments/deposit-deadline.service.ts`
- Create: `backend/src/payments/deposit-deadline.service.spec.ts`
- Create: `backend/src/payments/deposit-operation.processor.ts`
- Create: `backend/src/payments/deposit-operation.processor.spec.ts`
- Modify: `backend/src/payments/payments.module.ts`
- Modify: `backend/src/booking/booking-act.service.ts`
- Modify: `backend/src/booking/booking-act.service.spec.ts`
- Modify: `backend/test/fake-safe-deal.e2e-spec.ts`

- [ ] Add failing tests: fake handover cannot be confirmed without `Payment.SUCCEEDED` and `Deposit.HELD`; return confirmation sets `disputeWindowEndsAt = confirmedAt + snapshotted seconds`; due deposit schedules exactly one full REFUND; duplicate worker runs do not repeat it; timeout remains `PENDING`; success resolves the deposit and then moves `RETURNED → COMPLETED`; unresolved deposit blocks completion.
- [ ] Run `make backend-test` and confirm those tests fail.
- [ ] In `BookingActService.confirm`, under the same booking advisory lock, require a successful payment before fake `HANDOVER`, plus a held deposit when the snapshot contains one. Set the deadline only when `RETURN` is confirmed. Never read the current global window here; use the Booking snapshot.
- [ ] Implement `DepositDeadlineService` with the same lifecycle style as `BookingExpiryService`: skip timers in `NODE_ENV=test`, poll once per minute elsewhere, and expose `processDue(now)` for deterministic tests.
- [ ] For each due candidate, acquire `hashtext(bookingId)`, re-read Booking/deposit/dispute, and either create idempotency key `deposit:{depositId}:auto-refund` plus `RESOLVING`, or do nothing if a dispute/operation/state already wins.
- [ ] Implement `DepositOperationProcessor` with a five-second poll and public `processPending()` test hook. Atomically claim one due `PENDING` operation by setting a short `processingUntil` lease and incrementing `attempts`, call the provider outside the transaction, then lock the Booking/deposit again before applying the outcome. A second worker must observe the active lease and skip the operation.
- [ ] Apply operation results monotonically: timeout clears the lease, keeps `PENDING` and advances `nextAttemptAt` with bounded backoff; definitive decline clears the lease and sets only the operation `FAILED` plus a PII-free `AdminAuditLog` operational record; success clears the lease, increments the correct resolved amount once and never replays a succeeded provider ID.
- [ ] When successful operations make `refunded + released = amount`, set deposit `RESOLVED`; if Booking is `RETURNED`, the deadline passed and no unresolved dispute exists, issue a separate local `COMPLETE_AFTER_DEPOSIT_SETTLED` command with transition history/outbox. Do not include deposit in any owner payout calculation.
- [ ] Export a pure guard `assertDepositSettledForCompletionOrPayout` and use it in the completion command; no `Payout` table is added because the repository has no payout implementation yet.
- [ ] Run `make backend-test`, `make backend-test-e2e`, `make backend-build` and `git diff --check`.
- [ ] Commit only Task 5 files:

```bash
git commit -m "feat(payments): settle deposits after return"
```

## Task 6: Add participant financial disputes and private evidence

**Files:**

- Create: `backend/src/payments/dispute.service.ts`
- Create: `backend/src/payments/dispute.service.spec.ts`
- Create: `backend/src/payments/dispute.controller.ts`
- Create: `backend/src/payments/dto/create-dispute.dto.ts`
- Create: `backend/src/payments/dto/add-dispute-evidence.dto.ts`
- Create: `backend/src/payments/dto/dispute-response.dto.ts`
- Modify: `backend/src/payments/payments.module.ts`
- Modify: `backend/src/upload/upload.types.ts`
- Modify: `backend/src/upload/dto/request-upload-url.dto.ts`
- Modify: `backend/src/upload/upload.service.ts`
- Modify: `backend/src/upload/upload.service.spec.ts`
- Modify: `backend/test/fake-safe-deal.e2e-spec.ts`

- [ ] Add failing tests for one dispute per Booking, participant-only access, allowed reasons (`ITEM_DAMAGED`, `ITEM_LOST`, `OTHER`), `RETURNED + HELD + before deadline` window, and non-disclosing outsider responses.
- [ ] Add the exact race test: start `openDispute` and `processDue` against the same due boundary; after both finish, assert exactly one outcome is present—`DISPUTED` with no refund operation, or `RESOLVING/RESOLVED` with no dispute.
- [ ] Add failing upload tests for participant-bound `DISPUTE_EVIDENCE`, immutable intent binding, sanitizer/hash reuse, one-time consumption and no public URL.
- [ ] Run `make backend-test` and confirm the tests fail.
- [ ] Implement participant endpoints:

```text
POST /api/v1/bookings/:bookingId/disputes
GET  /api/v1/bookings/:bookingId/dispute
POST /api/v1/bookings/:bookingId/disputes/:disputeId/evidence
GET  /api/v1/bookings/:bookingId/disputes/:disputeId/evidence/:evidenceId/download-url
```

- [ ] `openDispute` must acquire the same Booking advisory lock as the deadline worker, re-read all state, create the single dispute, and move deposit `HELD → DISPUTED` in one transaction. It must not change Booking or Payment.
- [ ] Extend the upload request with `disputeId`; route `DISPUTE_EVIDENCE` to the established private bucket/quarantine/sanitize/hash pipeline and authorize only Booking participants.
- [ ] Consume the intent and create `DisputeEvidence` atomically. List responses expose evidence ID/hash/time only; each participant download re-checks participation and returns a short-lived private URL.
- [ ] Run `make backend-test`, `make backend-test-e2e`, `make backend-build` and `git diff --check`.
- [ ] Commit only Task 6 files:

```bash
git commit -m "feat(disputes): add participant deposit disputes"
```

## Task 7: Add capability-gated financial resolution and retry

**Files:**

- Create: `backend/src/payments/admin-dispute.controller.ts`
- Create: `backend/src/payments/dto/resolve-dispute.dto.ts`
- Modify: `backend/src/payments/dispute.service.ts`
- Modify: `backend/src/payments/dispute.service.spec.ts`
- Modify: `backend/src/payments/deposit.service.ts`
- Modify: `backend/src/payments/deposit-operation.processor.ts`
- Modify: `backend/src/payments/payments.module.ts`
- Modify: `backend/src/admin/first-admin-bootstrap.ts`
- Create: `backend/src/admin/first-admin-bootstrap.spec.ts`
- Create: `backend/src/admin/admin-any-capability.decorator.ts`
- Modify: `backend/src/admin/admin-session.guard.ts`
- Modify: `backend/test/admin-session.e2e-spec.ts`
- Modify: `backend/test/fake-safe-deal.e2e-spec.ts`

- [ ] Add failing e2e assertions: `SUPPORT` can list/read dispute evidence but cannot resolve; `DISPUTE` without `FINANCE` can read but cannot resolve; `FINANCE` without `DISPUTE` cannot read or resolve; expired/missing admin session gets `401`; both `DISPUTE` and `FINANCE` plus fresh MFA session can resolve once.
- [ ] Add failing service tests for full refund, partial refund/release, full lender release, negative/over/unequal totals, duplicate idempotency key, definitive failed operation and a separately authorized linked retry.
- [ ] Run `make backend-test` and confirm failures.
- [ ] Implement admin endpoints:

```text
GET  /api/v1/admin/disputes                         requires SUPPORT or DISPUTE
GET  /api/v1/admin/disputes/:id/evidence/:evidenceId/download-url requires SUPPORT or DISPUTE
POST /api/v1/admin/disputes/:id/resolve             requires DISPUTE + FINANCE
POST /api/v1/admin/deposit-operations/:id/retry     requires DISPUTE + FINANCE
```

- [ ] Add `@AdminAnyCapability(SUPPORT, DISPUTE)` metadata and make `AdminSessionGuard` enforce it as an any-of read rule while retaining the existing all-of behavior from `@AdminCapabilities` for mutation commands.
- [ ] Make `ResolveDisputeDto` require safe-integer `refundToBorrowerMinor`, `releaseToLenderMinor`, a 10–1000 character reason, and `Idempotency-Key`. Validate exact equality with the original deposit before writing.
- [ ] Under the Booking lock, set dispute `UNDER_REVIEW`, deposit `RESOLVING`, and append one operation for each positive leg. Zero legs create no fake provider call. Use keys derived from the resolution command and leg.
- [ ] Write one append-only audit entry containing actor, `FINANCE`, dispute/deposit IDs, request metadata, reason and minor amounts; include `requiredCapabilities: ['DISPUTE', 'FINANCE']` in metadata and no phone/address/provider payload.
- [ ] A failed operation stays immutable. Retry creates a new `PENDING` operation with `retryOfId`; the processor reuses no succeeded provider operation and resolves only after every required leg has one successful attempt.
- [ ] Permit `DISPUTE` and `FINANCE` in the guarded first-admin bootstrap parser, keeping the current deduplication, unknown-value rejection and audit behavior.
- [ ] Run `make backend-test`, `make backend-test-e2e`, `make backend-build` and `git diff --check`.
- [ ] Commit only Task 7 files:

```bash
git commit -m "feat(disputes): add audited financial resolution"
```

## Task 8: Expose the dispute queue in the operator UI

**Files:**

- Modify: `operator/src/api.ts`
- Modify: `operator/src/App.tsx`
- Modify: `operator/src/styles.css`
- Modify: `operator/README.md`

- [ ] Add exact TypeScript types using minor integers for dispute amount, refund, release, deposit status, deadline, evidence metadata and failed operations.
- [ ] Add API methods for the four admin routes from Task 7; keep CSRF/request ID/cookie behavior inside the existing `call` helper.
- [ ] Add a `disputes` page visible to sessions containing `SUPPORT` or `DISPUTE`. Show booking short ID, structured reason, description, deadline, deposit/status, evidence and failed-operation retry state; do not request/display phone, address or payment payload.
- [ ] Show resolution inputs and retry buttons only when the current session has both `DISPUTE` and `FINANCE`. Parse decimal RUB text to integer kopecks locally and reject more than two fractional digits before sending.
- [ ] After resolve/retry, reload the authoritative queue instead of mutating money state optimistically.
- [ ] Update README: manager `SUPPORT` is read-only; owner/finance needs `DISPUTE + FINANCE`; all current money is fake and production remains disabled.
- [ ] Run `make operator-build` and `git diff --check`.
- [ ] Commit only Task 8 files:

```bash
git commit -m "feat(operator): add deposit dispute queue"
```

## Task 9: Add the server policy and deposit field to mobile listings

**Files:**

- Create: `mobile/lib/features/payments/data/marketplace_policy_models.dart`
- Create: `mobile/lib/features/payments/data/marketplace_policy_models.freezed.dart`
- Create: `mobile/lib/features/payments/data/marketplace_policy_models.g.dart`
- Create: `mobile/lib/features/payments/data/marketplace_policy_service.dart`
- Create: `mobile/test/features/payments/marketplace_policy_service_test.dart`
- Modify: `mobile/lib/features/item/data/create_item_models.dart`
- Modify: `mobile/lib/features/item/data/create_item_models.freezed.dart`
- Modify: `mobile/lib/features/item/data/create_item_models.g.dart`
- Modify: `mobile/lib/features/item/data/owned_item_models.dart`
- Modify: `mobile/lib/features/item/data/owned_item_models.freezed.dart`
- Modify: `mobile/lib/features/item/data/owned_item_models.g.dart`
- Modify: `mobile/lib/features/item/presentation/create_item_screen.dart`
- Modify: `mobile/lib/features/item/presentation/edit_item_screen.dart`
- Modify: `mobile/test/features/item/create_item_service_test.dart`
- Modify: `mobile/test/features/item/create_item_screen_test.dart`
- Modify: `mobile/test/features/item/owned_items_service_test.dart`
- Modify: `mobile/test/features/item/edit_item_screen_test.dart`

- [ ] Add failing service tests for the exact `/marketplace-policy` envelope, offline disabled policy and fake maximum/version/window.
- [ ] Add failing widget/service tests: deposit controls absent offline; fake mode shows `Без залога / С залогом`; over-maximum and >2 decimals fail validation; exact kopecks are sent as `depositAmountMinor`; edit can clear with `0`; disabled policy omits the field and does not erase an existing value.
- [ ] Run `make mobile-test` and confirm failures.
- [ ] Add Freezed models matching Task 1. Provider retries are disabled like other server-contract providers so failures are explicit.
- [ ] Add `int? depositAmountMinor` to create/update commands. `null` means omitted, `0` means explicitly no deposit, positive means exact deposit. Persist draft selection and text without converting through `double`.
- [ ] In create/edit screens watch the policy provider. Render controls only when `deposit.enabled`; display maximum as formatted RUB; parse at submit with one shared string-to-minor helper.
- [ ] If policy loading fails, fail closed by hiding non-zero input and show a short retry message; never assume fake policy from `AppConfig.demoStubsEnabled`.
- [ ] Run `make mobile-gen`, `make mobile-analyze`, `make mobile-test` and `git diff --check`.
- [ ] Commit only Task 9 files:

```bash
git commit -m "feat(mobile): add policy-gated item deposit"
```

## Task 10: Replace the mobile demo with authoritative deposit/dispute UX

**Files:**

- Modify: `mobile/lib/features/booking/data/booking_models.dart`
- Modify: `mobile/lib/features/booking/data/booking_models.freezed.dart`
- Modify: `mobile/lib/features/booking/data/booking_models.g.dart`
- Modify: `mobile/lib/features/booking/data/booking_service.dart`
- Modify: `mobile/lib/features/booking/domain/booking_action_controller.dart`
- Delete: `mobile/lib/features/booking/domain/demo_payment_controller.dart`
- Modify: `mobile/lib/features/booking/presentation/booking_create_screen.dart`
- Modify: `mobile/lib/features/booking/presentation/booking_details_screen.dart`
- Modify: `mobile/test/features/booking/booking_service_test.dart`
- Modify: `mobile/test/features/booking/booking_screens_test.dart`

- [ ] Add failing model/service tests for exact minor breakdown, payment/deposit summary, fake success/decline/timeout endpoint, dispute create, evidence upload and authoritative reload.
- [ ] Add failing widget tests: offline card absent; fake confirmed borrower sees clearly labeled test checkout; success renders `HELD`; return shows deadline; valid window shows `Открыть финансовый спор`; lender and borrower can attach evidence; expired/resolved window hides the command; ordinary `Есть проблема` support remains separate.
- [ ] Run `make mobile-test` and confirm failures.
- [ ] Extend `ParticipantBooking` with nullable `payment`, `deposit` and `financialDispute`; render exact new amounts from minor units while retaining legacy response parsing for old offline bookings.
- [ ] Replace `DemoPaymentController` with `BookingService.fakeCheckout(bookingId, outcome, requestId)`. Keep `Успех`, `Отказ` and `Таймаут` controls only for `FAKE_SAFE_DEAL`, label them as test behavior, and invalidate details/list after every response.
- [ ] Update the pre-submit breakdown: rental, deposit, provisional fake fee, owner payout and total are separate rows; offline still says payment at handover and 0% platform fee.
- [ ] Add a dedicated financial-dispute dialog with allowed reason and 10–2000 character facts, then optional private image upload through the new evidence purpose. Do not route this command through `/support/tickets`.
- [ ] Show deposit lifecycle using user language: `Ожидает тестовой оплаты`, `Удерживается`, `Открыт спор`, `Возврат/выплата обрабатывается`, `Возвращён/распределён`, `Отменён`. Do not promise a real refund in fake mode.
- [ ] Keep address/contact access rules and ordinary support flow unchanged.
- [ ] Run `make mobile-gen`, `make mobile-analyze`, `make mobile-test` and `git diff --check`.
- [ ] Commit only Task 10 files:

```bash
git commit -m "feat(mobile): add server-backed deposit flow"
```

## Task 11: Synchronize source-of-truth notes and run the full verification gate

**Files:**

- Modify: `docs/adr/0005-monetized-safe-deal-provider.md`
- Modify: `MVP_CHECKLIST.md`
- Modify: `sosedi-roadmap.html`

- [ ] Update ADR-0005 consequences to say that the repository now contains a gated `FAKE_SAFE_DEAL` schema/API/operator/mobile test slice, while live provider integration and production activation remain forbidden and ADR status remains `PROPOSED`.
- [ ] Add matching dated `DOING 02.09.2026` notes to checklist sections 13.1 and 14: enumerate the fake-only domain/race/auth coverage, state that no checkbox/provider gate closes, and keep the tracked percentage unchanged.
- [ ] Mirror the same factual wording and status in `sosedi-roadmap.html` in this documentation task.
- [ ] Confirm `.codex/HANDOFF.md` is unchanged because no checklist point was closed.
- [ ] Run placeholder/type consistency scans:

```bash
rg -n "TO[D]O|TB[D]|implement[[:space:]]+later|заглушка без server state" backend/src mobile/lib operator/src docs/superpowers/plans/2026-09-02-safe-deal-deposit.md
rg -n "PAYMENT_PROVIDER_MODE|depositAmountMinor|FAKE_SAFE_DEAL|BookingDeposit|FinancialDispute" backend mobile operator ops scripts MVP_CHECKLIST.md sosedi-roadmap.html
```

  The first command may report historical text outside changed production code; inspect every match and remove any new unresolved placeholder from this feature.
- [ ] Run the complete relevant gate:

```bash
make backend-prisma-generate
make backend-lint-check
make backend-test
make backend-test-e2e
make backend-build
make operator-build
make mobile-gen
make mobile-analyze
make mobile-test
make environment-isolation-test
make release-gates-test
make security-scan
git diff --check
```

- [ ] Inspect `git status --short` and `git diff --stat`; verify the four pre-existing user paths in Global Constraints were not staged or overwritten.
- [ ] Commit only Task 11 documentation:

```bash
git commit -m "docs(payments): record fake deposit implementation"
```

- [ ] Final handoff must report: fake flow capabilities, production prohibition, exact verification results, remaining external provider/legal/KYC blockers, and the unchanged next checklist point from `.codex/HANDOFF.md`.
