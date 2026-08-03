# Sosedi Backend

NestJS monolith for the Sosedi P2P item-rental MVP.

The current product contract uses `Item`/`ItemPhoto`, `/api/v1/items` and one
product role, `USER`. A user may both borrow other users' items and publish
their own; mutation access is checked through object ownership.

## Current scope

- SMS OTP authentication with installation-bound rotating JWT sessions in
  Redis, self session listing, revoke-one/logout-all and refresh-family replay
  revocation.
- Public item list/card with coarse location and no pickup address.
- Owner-only item create/update/hide operations.
- Server-side `ALLOWED`/`RESTRICTED`/`PROHIBITED` category policy with mandatory
  safety notices and deny-by-default listing creation.
- Presigned item-photo upload with backend-generated keys, single-use intents
  and BullMQ image processing.
- Capability-scoped moderation/support admin sessions with TOTP MFA and
  single-use recovery codes. The operator contract uses an opaque Redis session
  in an `HttpOnly + Secure + SameSite=Strict` cookie and requires `X-CSRF-Token`
  for state changes; no admin JWT is returned to browser code.

Booking, production payments, KYC collection and public legal pages remain
gated by `MVP_CHECKLIST.md` and accepted ADRs. Do not expose those flows as
production-ready.

## Local development

Run commands from the repository root:

```bash
make infra-up
make backend-prisma-generate
make backend-dev
```

The API prefix is `/api/v1`. In non-production environments Swagger is
available at `/api/docs`, with OpenAPI JSON at `/api/docs-json`.

Copy required local values from `.env.example` into `backend/.env`. Production
secrets must not be committed.

## Checks

```bash
make backend-lint-check
make backend-test
make backend-build
make backend-test-e2e
```

`make backend-test-e2e` starts isolated PostgreSQL/PostGIS and Redis containers,
applies all Prisma migrations and runs the HTTP/DB contract tests. Stop them
afterward with:

```bash
make test-infra-down
```

## Project layout

```text
src/auth/        OTP, JWT and session lifecycle
src/users/       User profile API
src/categories/  Category launch whitelist
src/items/       Item REST API and public/private DTO
src/upload/      Presigned upload and photo processing
src/admin/       Capability-scoped operator endpoints
src/common/      API envelopes, workflow contracts and safe logging
prisma/          Schema, migrations and seed
test/            E2E contracts
```

The schema reference is [database-schema.md](../docs/database-schema.md), access
rules are in [endpoint-access-matrix.md](../docs/endpoint-access-matrix.md), and
workflow states are defined in
[workflow-state-machines.md](../docs/workflow-state-machines.md).
