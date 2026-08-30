# Local Pilot Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Сделать локальный закрытый MVP воспроизводимым одной seed-командой и одной smoke-командой, улучшить photo-first публикацию и подготовить проверяемые материалы пилота без обхода production gates.

**Architecture:** Локальный seed работает только при явном opt-in и только с loopback PostgreSQL, ничего не удаляет и идемпотентно обновляет собственные fixture-записи. Pilot smoke оркестрирует существующие проверки в изолированной test-БД, всегда выполняет cleanup и отдельно проверяет карту screenshot-путей. Flutter меняется только в существующем трёхшаговом Create Item flow: выбранные `XFile` получают видимое preview без нового состояния или backend-контракта.

**Tech Stack:** NestJS/TypeScript, Prisma/PostgreSQL, Node.js test runner, Make, Flutter/Riverpod, `flutter_test`.

**Spec:** `MVP_CHECKLIST.md`, разделы 8.2, 12, 18 и 19; утверждённый в чате срез от 30.08.2026.

## Global Constraints

- Закрытый pilot использует `PAY_ON_HANDOVER` только как демонстрационное допущение и комиссию Sosedi 0%; production Payments не открываются.
- Настоящие MapKit, FCM/RuStore Push, KYC, store signing и legal/provider gates остаются закрыты.
- Seed запрещён для production/non-loopback БД, ничего не удаляет и не создаёт bypass endpoint.
- Не изменять пользовательский untracked `docs/APP_WORKFLOW_GUIDE.md`.
- Каждый product/code срез следует red-green-refactor; документация и screenshot artifacts проверяются smoke/schema-командой.

---

### Task 1: Идемпотентные данные локального пилота

**Files:**
- Create: `backend/src/operations/local-pilot-seed.ts`
- Create: `backend/src/operations/local-pilot-seed.spec.ts`
- Create: `backend/scripts/seed-local-pilot.ts`
- Create: `backend/test/local-pilot-seed.e2e-spec.ts`
- Modify: `backend/package.json`
- Modify: `Makefile`

**Interfaces:**
- Produces: `assertLocalPilotSeedAllowed(environment: NodeJS.ProcessEnv): void`.
- Produces: `seedLocalPilotData(prisma: PrismaClient): Promise<{ users: number; items: number; favorites: number }>`.
- Produces: `make pilot-seed`, which runs migrations, canonical category seed and the guarded local fixture seed.

- [x] **Step 1: Write the failing guard unit tests**

```ts
expect(() => assertLocalPilotSeedAllowed({
  NODE_ENV: 'production',
  ALLOW_LOCAL_PILOT_SEED: 'true',
  DATABASE_URL: 'postgresql://user:pass@localhost:5432/sosedi',
})).toThrow('production');

expect(() => assertLocalPilotSeedAllowed({
  NODE_ENV: 'development',
  ALLOW_LOCAL_PILOT_SEED: 'true',
  DATABASE_URL: 'postgresql://user:pass@db.example/sosedi',
})).toThrow('loopback');
```

- [x] **Step 2: Run unit test and confirm RED**

Run: `cd backend && npm test -- --runInBand src/operations/local-pilot-seed.spec.ts`

Expected: FAIL because `local-pilot-seed` does not exist.

- [x] **Step 3: Implement the minimal guard and fixture upserts**

Use two deterministic local users, six approved listings across the already seeded launch-category slugs, one pending owned listing and two favorites. Resolve categories by slug and fail with a readable error if `npm run prisma:seed` was not run. Use `ownerId_clientRequestId` for idempotent item upserts; do not delete unrelated rows.

- [x] **Step 4: Run guard unit test and confirm GREEN**

Run: `cd backend && npm test -- --runInBand src/operations/local-pilot-seed.spec.ts`

Expected: PASS.

- [x] **Step 5: Write the failing real-DB idempotency test**

The e2e test creates the six required categories, calls `seedLocalPilotData` twice, then checks literal counts and verifies that the public items endpoint returns only approved fixtures without `address`, `latitude` or `longitude`.

- [x] **Step 6: Run e2e test and confirm RED, then complete the minimal seed implementation**

Run: `make test-infra-up && make backend-test-db-migrate && cd backend && NODE_ENV=test TEST_DATABASE_URL="$TEST_DATABASE_URL" TEST_REDIS_URL="$TEST_REDIS_URL" npm run test:e2e -- --runInBand test/local-pilot-seed.e2e-spec.ts`

Expected before completion: FAIL on missing fixture behavior. Expected after completion: PASS with unchanged counts after the second seed.

- [x] **Step 7: Add guarded CLI and Make command**

`backend/scripts/seed-local-pilot.ts` loads `dotenv/config`, runs the guard before constructing Prisma, calls `seedLocalPilotData`, prints only counts and disconnects. Add `pilot:seed` to `backend/package.json` and `pilot-seed` to `Makefile`.

`infra-up` также ждёт healthcheck PostgreSQL/Redis, чтобы первый seed не зависел
от скорости холодного старта контейнеров.

- [x] **Step 8: Verify and commit**

Run: `make backend-lint-check && make backend-test && make backend-build`

Commit: `feat(pilot): add guarded local fixture seed`

### Task 2: Проверка screenshot-карты приложения

**Files:**
- Create: `scripts/verify-app-user-paths.mjs`
- Create: `scripts/verify-app-user-paths.test.mjs`
- Modify: `Makefile`

**Interfaces:**
- Produces: `verifyAppUserPaths({ htmlPath, screenshotsDir }): { references: number; files: number }`.
- Produces: `make app-user-paths-check`.

- [x] **Step 1: Write failing behavior tests**

Use temporary directories and real HTML/files. One test accepts safe relative PNG
references and legitimate reuse of one screen in several journeys. Separate tests
reject a missing referenced PNG, path traversal/absolute URL and an unreferenced
PNG in the screenshots directory.

- [x] **Step 2: Run and confirm RED**

Run: `node --test scripts/verify-app-user-paths.test.mjs`

Expected: FAIL because verifier does not exist.

- [x] **Step 3: Implement minimal verifier**

Extract only `src="screenshots/<safe-name>.png"`, require at least one image, compare unique references with the actual `.png` basenames and return counts. CLI defaults to `docs/app-user-paths.html` and `docs/screenshots`.

- [x] **Step 4: Run and confirm GREEN**

Run: `node --test scripts/verify-app-user-paths.test.mjs && node scripts/verify-app-user-paths.mjs`

Expected: tests pass; every reference resolves and all 29 PNG files are used.

- [x] **Step 5: Add Make target and commit**

Commit: `test(app): verify screenshot user-path map`

### Task 3: Одна безопасная команда pilot smoke

**Files:**
- Create: `scripts/run-local-pilot-smoke.mjs`
- Create: `scripts/run-local-pilot-smoke.test.mjs`
- Modify: `Makefile`

**Interfaces:**
- Produces: `runLocalPilotSmoke(run): Promise<void>`.
- Produces: `make pilot-smoke`.

- [x] **Step 1: Write failing runner tests**

Assert literal stage order: `make check`, `make backend-test-e2e`, `make mobile-screenshots`, `make app-user-paths-check`. Assert `make test-infra-down` is called after success and after a stage failure; original failure wins unless only cleanup fails.

- [x] **Step 2: Run and confirm RED**

Run: `node --test scripts/run-local-pilot-smoke.test.mjs`

Expected: FAIL because runner does not exist.

- [x] **Step 3: Implement sequential runner with `finally` cleanup**

Use `node:child_process.spawn` with inherited stdio for the CLI path. Do not accept arbitrary user commands and do not print environment variables.

- [x] **Step 4: Run and confirm GREEN**

Run: `node --test scripts/run-local-pilot-smoke.test.mjs`

Expected: PASS.

- [x] **Step 5: Add Make target and commit**

Commit: `test(pilot): add isolated golden-path smoke`

### Task 4: Photo-first preview в публикации

**Files:**
- Modify: `mobile/test/features/item/create_item_screen_test.dart`
- Modify: `mobile/lib/features/item/presentation/create_item_screen.dart`
- Modify: `mobile/tool/capture_client_screenshots_test.dart`
- Modify: `docs/screenshots/11-create-item.png`

**Interfaces:**
- Existing `ItemPhotoPicker.pick(): Future<List<XFile>>` stays unchanged.
- Produces: selected-photo cards with thumbnail/fallback, one visible `Главное`, tap-to-cover and delete actions.

- [x] **Step 1: Write failing widget behavior test**

Return two valid in-memory PNG `XFile` values. After picking, assert two photo semantics/cards, exactly one `Главное`, tap the second card and assert its filename is marked main, then delete it and assert one card remains.

- [x] **Step 2: Run and confirm RED**

Run: `cd mobile && flutter test test/features/item/create_item_screen_test.dart`

Expected: FAIL because visual photo cards do not exist.

- [x] **Step 3: Implement minimal preview cards**

Replace filename-only `InputChip` wrap with a horizontal list. Each card reads its own `XFile` bytes in a `FutureBuilder`, uses `Image.memory(..., fit: BoxFit.cover)` and a code-native fallback, exposes explicit cover/delete semantics and reuses `_makeCover`/`_removePhoto`.

- [x] **Step 4: Run focused test and analyzer**

Run: `cd mobile && flutter test test/features/item/create_item_screen_test.dart && flutter analyze`

Expected: PASS, no analyzer issues.

- [x] **Step 5: Regenerate screenshot 11 and commit**

Override the picker in the screenshot fixture, tap `Добавить фото` before capture and run `make mobile-screenshots`.

Commit: `feat(mobile): preview listing photos before submit`

### Task 5: Pilot playbook и source-of-truth sync

**Files:**
- Create: `docs/closed-pilot-playbook.md`
- Modify: `README.md`
- Modify: `MVP_CHECKLIST.md`
- Modify: `sosedi-roadmap.html`
- Modify: `.codex/HANDOFF.md`

**Interfaces:**
- Documents exact `make pilot-seed`, backend/mobile start, `make pilot-smoke`, two golden paths, operator checklist, evidence fields and blockers.

- [x] **Step 1: Write the concise playbook**

Include: prerequisites, safe local seed contract, borrower/lender paths, operator/support path, start/stop commands, console OTP limitation, no real payments/MapKit/push/KYC, usability observation table and deletion of test artifacts. Do not include secrets or approved legal claims.

- [x] **Step 2: Synchronize tracked sources**

Add `DOING` evidence to checklist section 19 without marking human/device/external gates complete. Mirror the same state in the roadmap pilot card. Add commands to README and update handoff to the next open checklist item. Progress stays `339/488 = 69.5%` unless an existing counted checkbox is actually closed.

- [x] **Step 3: Verify documentation behavior**

Run: `make app-user-paths-check`, `make public-web-check`, and `rg -n "TBD|TODO|implement later|fill in" docs/closed-pilot-playbook.md` (expected no matches).

- [ ] **Step 4: Commit**

Commit: `docs(pilot): add local runbook and usability kit`

### Task 6: Full verification and review

**Files:**
- Review all files changed since the plan commit.

- [ ] **Step 1: Run the actual pilot smoke**

Run: `make pilot-smoke`

Expected: `make check`, all backend e2e, screenshot regeneration and app-map verifier pass; test containers are removed in `finally`.

- [ ] **Step 2: Run diff/security review**

Check `git diff --check`, verify no credential/phone/address leakage in logs or docs, confirm seed guard rejects production/non-loopback targets, and confirm `docs/APP_WORKFLOW_GUIDE.md` remains untracked and untouched.

- [ ] **Step 3: Re-read this plan and checklist requirements**

Mark only completed steps, record any external gates as blockers and do not call MapKit/payments/push/KYC production-ready.

- [ ] **Step 4: Final commit if verification changed artifacts**

Commit only directly related generated screenshots/checklist/handoff changes; do not push or deploy.
