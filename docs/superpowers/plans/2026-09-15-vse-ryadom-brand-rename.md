# «Всё рядом» Brand Rename Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Заменить пользовательское название «Соседи» / `Sosedi` на «Всё рядом» без миграции технических идентификаторов и без изменения графического знака.

**Architecture:** Ребрендинг выполняется точечно по пользовательским поверхностям: mobile, backend-generated copy, operator/public web и активные документы. Совместимые identifiers `sosedi` остаются неизменными; старый внешний лендинг на SprintHost не входит в задачу, а новый лендинг на Timeweb проектируется отдельно после оплаты hosting и выбора нового домена.

**Tech Stack:** Flutter/Dart, NestJS/TypeScript/Jest, React/Vite, Astro, Android manifest, iOS plist, Markdown/HTML.

**Spec:** [`docs/superpowers/specs/2026-09-15-vse-ryadom-brand-rename-design.md`](../specs/2026-09-15-vse-ryadom-brand-rename-design.md)

## Global Constraints

- Пользовательское написание: ровно `Всё рядом`, с буквой `ё`.
- Не менять `ru.sosedi.app`, Kotlin package, package names, cookie/storage keys, DB/Redis/Docker/S3/OCI identifiers, metrics, backup prefixes, env names, существующие URL и `sosedi.rs@yandex.ru`.
- Не переименовывать `SosediApp`, `SosediLogo`, файлы с `sosedi` и существующие migrations.
- Не изменять геометрию/цвета logo painter, SVG logo assets и растровые screenshots.
- Не перезаписывать пользовательские незакоммиченные изменения; перед каждым task проверять пересечение через `git status --short` и `git diff -- <file>`.
- Добавлять тест только для изменяемого наблюдаемого контракта; не создавать snapshot/golden tests.
- `MVP_CHECKLIST.md` остаётся источником статуса, `sosedi-roadmap.html` синхронизируется в той же задаче.

---

### Task 1: Mobile display name and wordmark

**Files:**
- Modify: `mobile/test/widget_test.dart`
- Modify: `mobile/test/features/booking/booking_screens_test.dart`
- Modify: `mobile/test/features/auth/auth_screens_test.dart`
- Modify: `mobile/lib/main.dart`
- Modify: `mobile/lib/shared/widgets/sosedi_logo.dart`
- Modify: `mobile/lib/features/auth/presentation/onboarding_screen.dart`
- Modify: `mobile/lib/features/booking/presentation/booking_details_screen.dart`
- Modify: `mobile/android/app/src/main/AndroidManifest.xml`
- Modify: `mobile/ios/Runner/Info.plist`

**Interfaces:**
- Consumes: existing `SosediApp` and `SosediLogo` code identifiers without renaming them.
- Produces: Flutter title, visible wordmark, semantics and native launcher display name `Всё рядом`.

- [ ] **Step 1: Change the widget expectations first**

In `mobile/test/widget_test.dart`, require the new wordmark and reject the old one:

```dart
expect(find.text('Всё рядом'), findsWidgets);
expect(find.text('Соседи'), findsNothing);
```

Change the affected booking expectations to `Комиссия «Всё рядом»`,
`Предварительная комиссия «Всё рядом»` and
`Заявление владельца, не проверка «Всё рядом».`. Rename the onboarding test
description from `Sosedi illustration` to `product illustration`; do not add a
layout-only test.

- [ ] **Step 2: Run the focused mobile tests and verify RED**

Run:

```bash
cd mobile && flutter test test/widget_test.dart test/features/booking/booking_screens_test.dart test/features/auth/auth_screens_test.dart
```

Expected: failure because source still renders the old brand.

- [ ] **Step 3: Apply the minimal mobile rename**

Set `MaterialApp.title`, the `SosediLogo` visible `Text` and semantics label to
`Всё рядом`. Change brand references in booking copy. Replace onboarding
accessibility phrases that begin with the old proper name with neutral
`Пользователи ...` phrases. Set Android `android:label` and iOS
`CFBundleDisplayName` to `Всё рядом`. Do not rename Dart classes/files or touch
the painter/SVG/assets.

- [ ] **Step 4: Format and verify GREEN**

Run:

```bash
cd mobile && dart format lib/main.dart lib/shared/widgets/sosedi_logo.dart lib/features/auth/presentation/onboarding_screen.dart lib/features/booking/presentation/booking_details_screen.dart test/widget_test.dart test/features/booking/booking_screens_test.dart test/features/auth/auth_screens_test.dart
cd .. && make mobile-analyze && make mobile-test
```

Expected: formatter succeeds, analyzer has no issues, all Flutter tests pass.

- [ ] **Step 5: Commit only Task 1 files**

```bash
git add mobile/lib/main.dart mobile/lib/shared/widgets/sosedi_logo.dart mobile/lib/features/auth/presentation/onboarding_screen.dart mobile/lib/features/booking/presentation/booking_details_screen.dart mobile/android/app/src/main/AndroidManifest.xml mobile/ios/Runner/Info.plist mobile/test/widget_test.dart mobile/test/features/booking/booking_screens_test.dart mobile/test/features/auth/auth_screens_test.dart
git commit -m "feat: rename mobile brand to Vse Ryadom"
```

### Task 2: Backend-generated brand and operator metadata

**Files:**
- Modify: `backend/src/auth/sms.service.spec.ts`
- Modify: `backend/src/auth/sms.service.ts`
- Modify: `backend/src/admin/admin-mfa.service.spec.ts`
- Modify: `backend/src/admin/admin-mfa.service.ts`
- Modify: `backend/src/swagger.setup.spec.ts`
- Modify: `backend/src/swagger.setup.ts`
- Modify: `operator/index.html`
- Modify: `backend/Dockerfile`
- Modify: `ops/monitoring/prometheus-alerts.yml`
- Modify: `ops/systemd/sosedi-postgres-backup.service`
- Modify: `ops/systemd/sosedi-postgres-backup.timer`
- Modify: `scripts/verify-alert-rules.mjs`
- Modify: `scripts/verify-alert-rules.test.mjs`

**Interfaces:**
- Consumes: existing SMS.ru request, TOTP enrollment, Swagger setup and technical `sosedi_*` metric/service identifiers.
- Produces: SMS text, TOTP issuer, Swagger/operator titles and human-readable operations descriptions using `Всё рядом`.

- [ ] **Step 1: Add backend contract assertions**

In `sms.service.spec.ts`, inspect the successful `fetch` call body as
`URLSearchParams` and assert:

```ts
expect(body.get('msg')).toBe('Код для входа во Всё рядом: 654321');
```

In `admin-mfa.service.spec.ts`, add one successful setup case that checks the
returned `otpauthUri` contains URL-encoded issuer `Всё рядом` and does not
contain `Соседи`. In `swagger.setup.spec.ts`, read `/api/docs-json` and assert
`response.body.info.title === 'Всё рядом API'`.

- [ ] **Step 2: Run focused backend tests and verify RED**

Run:

```bash
cd backend && npm test -- --runInBand src/auth/sms.service.spec.ts src/admin/admin-mfa.service.spec.ts src/swagger.setup.spec.ts
```

Expected: new brand assertions fail against existing source.

- [ ] **Step 3: Apply the minimal backend/operator rename**

Change only human-readable values:

```ts
msg: `Код для входа во Всё рядом: ${code}`
buildTotpUri('Всё рядом', phone, secret)
.setTitle('Всё рядом API')
```

Set `operator/index.html` title to `Всё рядом · Оператор`. Rename only readable
OCI labels, alert annotations and systemd descriptions; keep metric names,
cookie names, unit filenames and executable paths containing `sosedi`.

- [ ] **Step 4: Verify backend and operator**

Run:

```bash
make backend-lint-check
make backend-test
make backend-build
make operator-build
make alerts-test
```

Expected: every command exits 0.

- [ ] **Step 5: Commit only Task 2 files**

```bash
git add backend/src/auth/sms.service.spec.ts backend/src/auth/sms.service.ts backend/src/admin/admin-mfa.service.spec.ts backend/src/admin/admin-mfa.service.ts backend/src/swagger.setup.spec.ts backend/src/swagger.setup.ts operator/index.html backend/Dockerfile ops/monitoring/prometheus-alerts.yml ops/systemd/sosedi-postgres-backup.service ops/systemd/sosedi-postgres-backup.timer scripts/verify-alert-rules.mjs scripts/verify-alert-rules.test.mjs
git commit -m "feat: rename service-facing brand to Vse Ryadom"
```

### Task 3: Public legal web brand

**Files:**
- Modify: `public-web/src/layouts/BaseLayout.astro`
- Modify: `public-web/src/pages/index.astro`
- Modify: `public-web/src/pages/support.astro`
- Modify: `public-web/src/pages/account-deletion.astro`
- Modify: `public-web/src/pages/documents/index.astro`
- Modify: `public-web/src/data/documents.ts`
- Modify: `public-web/scripts/smoke.mjs`

**Interfaces:**
- Consumes: existing public routes, approved support email and unchanged logo asset path.
- Produces: page title/header/description/legal draft prose branded `Всё рядом`.

- [ ] **Step 1: Strengthen the public web smoke**

For `/`, require the built HTML to contain `Всё рядом`; for every route reject
the proper-name variants with this exact regular expression:

```js
if (/Соседи|Sosedi/.test(html)) {
  throw new Error(`${route} contains the retired user-facing brand`);
}
```

Do not reject lowercase `соседи` when it is the ordinary Russian noun.

- [ ] **Step 2: Run the web smoke and verify RED**

Run:

```bash
make public-web-check
```

Expected: smoke fails because generated HTML contains the old proper name.

- [ ] **Step 3: Rename public copy only**

Change page metadata, header and legal draft prose to `Всё рядом`. Keep
`/logo/sosedi-mark-orange.svg`, the SVG file bytes, all routes and
`sosedi.rs@yandex.ru` unchanged.

- [ ] **Step 4: Verify GREEN and commit**

Run:

```bash
make public-web-check
```

Expected: typecheck, lint, build and eight-route smoke pass.

```bash
git add public-web/src/layouts/BaseLayout.astro public-web/src/pages/index.astro public-web/src/pages/support.astro public-web/src/pages/account-deletion.astro public-web/src/pages/documents/index.astro public-web/src/data/documents.ts public-web/scripts/smoke.mjs
git commit -m "feat: rename public web brand to Vse Ryadom"
```

### Task 4: Active documentation and roadmap

**Files:**
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `MVP_CHECKLIST.md`
- Modify: `OWNER_ACTIONS.md`
- Modify: `DEVELOPMENT_BEST_PRACTICES.md`
- Modify: `backend/README.md`
- Modify: `mobile/README.md`
- Modify: `operator/README.md`
- Modify: `docs/APP_WORKFLOW_GUIDE.md`
- Modify: `docs/adr/0001-paid-neighbor-item-rental.md`
- Modify: `docs/adr/0005-monetized-safe-deal-provider.md`
- Modify: `docs/adr/0006-mixed-p2p-and-first-party-supply.md`
- Modify: `docs/adr/README.md`
- Modify: `docs/app-screen-schemes.html`
- Modify: `docs/app-user-paths.html`
- Modify: `docs/backend-technologies-mini-guide.html`
- Modify: `docs/backend-technologies-mini-guide.md`
- Modify: `docs/booking-contract.md`
- Modify: `docs/data-retention-and-export.md`
- Modify: `docs/database-schema.md`
- Modify: `docs/endpoint-access-matrix.md`
- Modify: `docs/monitoring-alert-runbooks.md`
- Modify: `docs/monitoring.md`
- Modify: `docs/payment-provider-comparison.md`
- Modify: `docs/store-ugc-requirements.md`
- Modify: `docs/testing.md`
- Modify: `docs/client-demo-2026-09-09.md`
- Modify: `sosedi-roadmap.html`

**Interfaces:**
- Consumes: approved brand decision and unchanged technical identifiers.
- Produces: active project/legal/provider/operations prose consistent with `Всё рядом` and synchronized roadmap.

- [ ] **Step 1: Review overlap before editing**

Run:

```bash
git status --short
git diff -- docs/client-demo-2026-09-09.md MVP_CHECKLIST.md OWNER_ACTIONS.md sosedi-roadmap.html
```

Preserve all non-brand user edits. Historical plans/specs remain unchanged; they
are evidence of decisions made under the earlier name. Technical examples and
actual URLs/identifiers containing `sosedi` remain literal.

- [ ] **Step 2: Replace active prose deliberately**

Use `«Всё рядом»` where the text names the product or platform. Use `Всё рядом`
without quotes only in headings/titles or where grammar requires it. Do not
alter ordinary lowercase noun `соседи`, code symbols, commands, paths, domains,
emails, IDs or filenames.

- [ ] **Step 3: Close the brand-readiness checklist item**

Change only the new canonical brand item from `[ ]` to `[x]` after Tasks 1–4
are verified. Add a dated `DONE` note with the exact validation commands and
state that screenshots/new logo/new Timeweb landing remain separate. Update the
roadmap counterpart and recompute counts from checkbox lines.

- [ ] **Step 4: Validate documentation and commit**

Run:

```bash
git diff --check
make app-user-paths-check
rg -n "Соседи|Sosedi" README.md MVP_CHECKLIST.md OWNER_ACTIONS.md DEVELOPMENT_BEST_PRACTICES.md backend/README.md mobile/README.md operator/README.md docs sosedi-roadmap.html
```

Classify every remaining match as an approved historical or technical exception;
fix any active brand copy. Then commit only the files listed in this task:

```bash
git add AGENTS.md README.md MVP_CHECKLIST.md OWNER_ACTIONS.md DEVELOPMENT_BEST_PRACTICES.md backend/README.md mobile/README.md operator/README.md docs/APP_WORKFLOW_GUIDE.md docs/adr/0001-paid-neighbor-item-rental.md docs/adr/0005-monetized-safe-deal-provider.md docs/adr/0006-mixed-p2p-and-first-party-supply.md docs/adr/README.md docs/app-screen-schemes.html docs/app-user-paths.html docs/backend-technologies-mini-guide.html docs/backend-technologies-mini-guide.md docs/booking-contract.md docs/data-retention-and-export.md docs/database-schema.md docs/endpoint-access-matrix.md docs/monitoring-alert-runbooks.md docs/monitoring.md docs/payment-provider-comparison.md docs/store-ugc-requirements.md docs/testing.md docs/client-demo-2026-09-09.md sosedi-roadmap.html
git commit -m "docs: rename product to Vse Ryadom"
```

`AGENTS.md` is intentionally ignored and may not be staged; verify its local
content separately if `git add` reports that it is ignored.

### Task 5: Final compatibility and repository verification

**Files:**
- Modify: `.codex/HANDOFF.md`

**Interfaces:**
- Consumes: completed Tasks 1–4.
- Produces: evidence that the brand changed without an identifier migration and a precise next checklist pointer.

- [ ] **Step 1: Prove technical identifiers remain unchanged**

Run:

```bash
git diff d3cbee7..HEAD -- mobile/android/app/build.gradle.kts mobile/android/app/src/main/kotlin/ru/sosedi/app/MainActivity.kt mobile/ios/Runner.xcodeproj/project.pbxproj docker-compose.yml docker-compose.test.yml docker-compose.production.yml Makefile backend/.env.example operator/src/api.ts
```

Expected: no rename of `ru.sosedi.app`, Kotlin package, DB/Redis/Docker names,
cookies, S3 names or metrics. Human-readable descriptions may be the only
intentional exception in files explicitly listed by Task 2.

- [ ] **Step 2: Run the full project check**

Run:

```bash
make check
```

Expected: exit 0 for configuration, backend, operator, public web and mobile
checks.

- [ ] **Step 3: Verify repository state and checklist arithmetic**

Run:

```bash
git diff --check
awk 'BEGIN{todo=done=na=0} /^- \[ \]/{todo++} /^- \[x\]/{done++} /^- \[~\]/{na++} END{printf "TODO=%d DONE=%d N/A=%d DENOM=%d PERCENT=%.1f%%\n",todo,done,na,todo+done,100*done/(todo+done)}' MVP_CHECKLIST.md
git status --short
```

Expected: no whitespace errors; arithmetic matches roadmap; only known
pre-existing user-owned changes remain outside the brand commits.

- [ ] **Step 4: Rewrite handoff and commit completion evidence**

Rewrite `.codex/HANDOFF.md` to no more than 8 lines/800 characters with the
brand item, results, checks, the exact next `[ ]` item, source section, and the
new landing/store external blockers. Do not stage this ignored local file.

If Task 5 required tracked evidence corrections, commit only those corrections:

```bash
git add MVP_CHECKLIST.md sosedi-roadmap.html
git commit -m "docs: record Vse Ryadom rename verification"
```
