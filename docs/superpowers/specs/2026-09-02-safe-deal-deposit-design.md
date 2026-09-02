# Safe Deal deposit design

**Date:** 2026-09-02

**Status:** APPROVED DESIGN; production activation remains gated

**Related source of truth:** `MVP_CHECKLIST.md` sections 13, 13.1 and 14

**Related ADR:** `docs/adr/0005-monetized-safe-deal-provider.md` (`PROPOSED`)

## Context

Sosedi currently supports the zero-commission `PAY_ON_HANDOVER` pilot. The Item,
Booking snapshot and mobile price breakdown already contain an optional
`depositAmount`, but backend and database constraints accept only `null` or zero.
The existing fake payment provider does not change server-side Payment or Booking
state.

The product owner wants an optional refundable deposit for the future Safe Deal
scenario. The deposit must be held by the payment provider, not transferred
directly between users or received by Sosedi. Production money movement remains
forbidden until the provider, legal, accounting and KYC gates in the checklist
are satisfied and ADR-0005 (or its successor) is `ACCEPTED`.

## Goals

- Model and test the deposit lifecycle before production provider integration.
- Keep one checkout for the borrower with a transparent price breakdown.
- Keep Booking, Payment, Deposit, Dispute and Payout as independent state
  machines.
- Support full refund, partial release to the lender and full release to the
  lender after an authorized dispute decision.
- Keep the current `PAY_ON_HANDOVER` pilot unchanged and unable to accept a
  non-zero deposit.
- Make fake Safe Deal available only in local/staging and impossible to start in
  production.

## Non-goals

- A live YooKassa adapter, real checkout, real refund or real payout.
- Selecting a numeric production deposit cap or dispute-window duration before
  provider and legal evidence exists.
- A general ledger, wallet, user balance or arbitrary payment orchestration
  framework.
- Charging damage above the snapshotted deposit.
- Using the deposit as a cancellation or no-show penalty.
- Enabling non-zero deposits in the zero-commission `PAY_ON_HANDOVER` pilot.

## Product rules

1. A lender may choose either no deposit or one fixed RUB deposit for an Item.
2. The deposit is optional. A single global maximum applies to all launch
   categories; category-specific formulas are outside MVP.
3. The active Safe Deal policy supplies the maximum, policy version and dispute
   window. Missing values disable non-zero deposits; the server does not invent
   defaults.
4. Booking creation stores the exact deposit and policy version in the immutable
   terms snapshot. Later Item or policy changes do not alter an existing Booking.
5. The borrower performs one checkout and sees separate rental, deposit,
   platform fee and total rows before payment.
6. Cancellation before confirmed handover always cancels or fully refunds the
   deposit. Any future cancellation fee is separate from the deposit.
7. After both parties confirm return, the deposit stays held until the
   snapshotted dispute window ends.
8. If no dispute is open at the deadline, the complete deposit is returned to
   the borrower automatically.
9. A dispute resolution specifies `refundToBorrower` and `releaseToLender`.
   Both are non-negative and their sum must equal the original deposit.
10. Normal completion never includes the deposit in the lender payout. Only the
    amount released by an authorized dispute decision can go to the lender.
11. Sosedi never charges an additional damage amount above the deposit in this
    MVP flow.

## Chosen architecture

### Aggregate boundaries

- `Item.depositAmount` remains the lender's optional offer term.
- `Booking.termsSnapshot` remains the immutable participant-facing contract.
- `Payment` owns the single checkout and overall provider payment/deal identity.
- A new one-to-one `BookingDeposit` owns only refundable-funds lifecycle and
  resolved amounts.
- A minimal financial `Dispute` is separate from ordinary `GENERAL` support
  tickets. Support staff may collect evidence but cannot decide money movement.
- `Payout` remains independent and is blocked until the dispute window is closed
  and the deposit is resolved.

No provider callback may directly mutate Booking state. Each aggregate accepts
only its own commands; cross-aggregate consequences are delivered through the
existing transactional outbox/worker pattern and re-check their preconditions.

### Server modes and policy

The backend has one explicit payment scenario, not generic feature flags:

- `PAY_ON_HANDOVER`: non-zero deposits are rejected exactly as today.
- `FAKE_SAFE_DEAL`: local/staging only; enables deterministic fake provider
  commands and the Safe Deal UI contract.
- `SAFE_DEAL`: reserved for the future production adapter and rejected until its
  complete mandatory configuration is present.

`FAKE_SAFE_DEAL` must fail startup when the runtime environment is production.
The production release gate must reject `SAFE_DEAL` without an accepted ADR,
provider evidence, policy version, maximum deposit, dispute duration and the
required provider/KYC configuration.

The API exposes one narrow `/api/v1/marketplace-policy` response containing the
active payment scenario and, when applicable, deposit currency, maximum and
policy version. This is an active business contract consumed by mobile, not a
general flag service.

## Data model

### Deposit status

`BookingDeposit` uses the following monotonic lifecycle:

- `PENDING`: the checkout/deal has not confirmed the hold.
- `HELD`: the provider has confirmed that the deposit is held.
- `DISPUTED`: a participant opened a valid dispute before automatic release.
- `RESOLVING`: refund/release operations were requested and are not all final.
- `RESOLVED`: the required operations succeeded and resolved amounts sum to the
  original deposit.
- `CANCELLED`: no hold occurred, or a pre-handover cancellation voided it.

Provider failure is not a terminal deposit status. The aggregate remains in its
last truthful state, while the failed operation records a redacted error and can
be retried idempotently.

### BookingDeposit

The minimal persistent fields are:

- `id`, unique `bookingId`;
- exact `amount`, `currency = RUB`, `policyVersion`;
- `status`;
- `disputeWindowEndsAt` set from server time when return is confirmed;
- exact `refundedAmount` and `releasedToLenderAmount`, initially zero;
- timestamps.

Database constraints enforce non-negative amounts, resolution not exceeding the
deposit and, for `RESOLVED`, exact equality:

`refundedAmount + releasedToLenderAmount = amount`.

The database may continue storing monetary values as `Decimal(10,2)` during the
pre-provider slice. Domain and fake-provider calculations use integer kopecks or
Prisma Decimal string conversion and never JavaScript/Dart binary-float
arithmetic. New live Safe Deal wire contracts use minor units; the complete
legacy REST/mobile money migration remains part of the provider-specific gate.

### DepositOperation

Each hold, cancel, refund or lender-release request creates one bounded operation
record with:

- deposit, kind and exact amount;
- unique idempotency key;
- provider operation ID when one exists;
- monotonic `PENDING/SUCCEEDED/FAILED` operation state;
- redacted provider error code and timestamps.

This is an operation journal for one deposit flow, not a universal accounting
ledger. A retryable transport/provider timeout keeps the operation `PENDING` and
reuses its idempotency key. `FAILED` is reserved for a definitive provider
failure; a separately authorized retry then creates a new linked operation and
does not rewrite the failed record.

### Financial dispute

The MVP permits at most one financial dispute per Booking. It records opener,
server timestamps, structured reason, lifecycle, resolver, resolution reason and
the two exact resolution amounts. Private evidence reuses the established safe
upload pipeline with participant/object authorization and no public object URL.

Ordinary support remains `GENERAL`. A manager with `SUPPORT` may read the linked
case and evidence through an audited capability but cannot call financial
commands. Resolution requires `DISPUTE` and `FINANCE`, fresh step-up MFA, a
reason and an idempotency key.

## State flow

1. Item create/update accepts a non-zero deposit only under an active Safe Deal
   policy and within its maximum.
2. Booking creation snapshots the deposit and policy. A non-zero legacy Item
   remains fail-closed if the current payment scenario cannot support it.
3. Lender confirmation permits one checkout for rental plus deposit. A successful
   fake/provider event advances Payment and Deposit independently; it does not
   advance Booking.
4. Pre-handover cancellation atomically records the Booking command and schedules
   a full deposit cancel/refund if needed.
5. Confirmed return changes Booking to `RETURNED` and records the deposit deadline
   from the snapshotted policy.
6. At the deadline a worker locks Booking/Deposit and either starts full refund
   or observes an existing dispute.
7. Opening a dispute locks the same records. The database race permits exactly
   one outcome: automatic refund or `DISPUTED`.
8. Authorized resolution validates the amount invariant and writes the decision,
   audit entry and required provider operations atomically.
9. Successful operation results accumulate resolved amounts. Deposit becomes
   `RESOLVED` only when every required operation succeeds.
10. Booking completion and ordinary payout re-check that the deadline passed,
    no unresolved dispute exists and Deposit is resolved or absent.

## API and mobile behavior

- Item create/edit shows `Без залога / С залогом` only when the server policy
  permits it.
- Booking preview and participant details show the complete immutable breakdown,
  payment scenario, deposit policy version, deposit status and dispute deadline.
- A participant can open a dispute only for their Booking and only inside the
  server-derived window.
- Admin financial resolution uses a dedicated command endpoint such as
  `POST /api/v1/admin/disputes/:id/resolve`; there is no generic status mutation.
- Mobile invalidates stale participant details after deposit/refund events and
  reloads authoritative state from the backend.
- Push, when later enabled, carries only an opaque `eventId`; the in-app inbox
  remains the source of truth.

## Security and audit

- Participant and object predicates run before dispute/evidence data is loaded;
  outsiders receive a non-disclosing response.
- Manager access is limited to support/evidence collection. Financial resolution
  is least-privilege and step-up protected.
- Every decision and provider operation writes a PII-free audit record with actor,
  capability, target, reason, request ID and amount metadata, but no phone,
  address, token, payment credential, checkout URL or raw provider payload.
- Provider callbacks are idempotent and monotonic. Duplicate, replayed or
  out-of-order events cannot repeat a refund/release or revert a final result.
- No PAN/CVC, payout credential or KYC document is collected by the Sosedi
  backend for this design.

## Error handling

- Missing or inconsistent Safe Deal policy rejects non-zero deposit input and
  fails closed.
- A provider timeout leaves the operation retryable and does not claim success.
- Partial external completion keeps Deposit in `RESOLVING`; completed operations
  are not repeated, and remaining operations are retried with their original
  idempotency keys.
- A failed refund/release creates an operational inbox/alert without exposing raw
  provider data.
- Deal expiry, insufficient provider balance or unsupported partial release must
  block production activation unless the provider contract defines a recoverable
  path. The fake provider has deterministic success, decline and timeout cases.

## Tests

Only tests that protect a business rule, money invariant or authorization boundary
are added:

- unit: optional deposit, policy maximum, immutable snapshot and lifecycle;
- unit: pre-handover full refund and resolution amount equality;
- integration: checkout to hold, return to automatic full refund;
- integration: dispute-open versus auto-refund race;
- integration: partial refund/release, duplicate callbacks and idempotent retry;
- integration: Booking completion and Payout blocked by unresolved deposit;
- authorization: outsider, support-only manager, missing/stale step-up and
  authorized finance resolver;
- mobile provider/widget: policy-controlled field, price breakdown, truthful
  status, deadline and dispute action;
- startup/release validation: fake mode and incomplete live mode are rejected in
  production.

No visual snapshot/golden tests or tests of provider SDK internals are added.

## Rollout and rollback

1. Add schema, domain service, fake provider behavior and tests for
   `FAKE_SAFE_DEAL` in local/staging.
2. Keep production and the closed zero-commission pilot on `PAY_ON_HANDOVER`;
   non-zero deposits continue to be rejected there.
3. Obtain provider terms and legal/accounting decisions, accept the payment and
   KYC ADRs, and supply explicit policy values.
4. Add and contract-test the selected provider adapter before enabling
   `SAFE_DEAL` in staging and then production.
5. Roll back by switching to `PAY_ON_HANDOVER`; this blocks new non-zero deposits
   but does not erase existing financial records. Any live in-flight Safe Deal
   must be reconciled and completed before adapter removal.

## Verification criteria

The pre-provider implementation is ready for review when:

- the fake end-to-end paths pass without real money;
- database constraints and concurrency tests prove the amount and race
  invariants;
- mobile never offers a deposit against a backend policy that forbids it;
- production startup cannot enable fake or incomplete Safe Deal;
- no current `PAY_ON_HANDOVER` behavior regresses;
- `MVP_CHECKLIST.md` remains open for every external provider/legal gate and no
  production-readiness claim is made.
