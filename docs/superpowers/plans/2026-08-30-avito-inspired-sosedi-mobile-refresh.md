# Avito-Inspired Sosedi Mobile Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Обновить все пользовательские Flutter-экраны до спокойного photo-first marketplace-интерфейса с механикой, знакомой по Avito, но с цветами, текстами и идентичностью Sosedi и со встроенным Onest Variable.

**Architecture:** Сохраняем существующую feature-based структуру, GoRouter shell, Riverpod providers, services, DTO и бизнес-состояния. Меняется только presentation/theme слой. Каждая партия сначала фиксирует один проверяемый UI/accessibility-контракт, затем меняет только перечисленные виджеты, прогоняет существующие поведенческие тесты, обновляет реальные route screenshots и проходит отдельный review checkpoint.

**Tech Stack:** Flutter 3 / Dart 3, Material 3, Riverpod, GoRouter, `flutter_test`, bundled Onest Variable 2.001, существующий screenshot harness и Make targets проекта.

**Spec:** `docs/superpowers/specs/2026-08-30-avito-inspired-sosedi-mobile-design.md`; source of truth — `MVP_CHECKLIST.md`, раздел 8.2.

## Global Constraints

- Не менять REST API, Freezed/JSON DTO, providers, services, route paths, auth intent, booking/payment FSM или legal/privacy gates.
- Не добавлять новые продуктовые возможности, зависимости, design-system package, network fonts, gradients, skeleton package или generated illustrations.
- Не извлекать общий presentation widget, пока один и тот же визуальный и поведенческий паттерн не нужен минимум трём экранам.
- Не трогать legacy `HomeScreen`: `/home` уже безопасно перенаправляется в `/catalog`; существующий тест доступности всё равно должен проходить.
- Сохранять точный адрес, контакты и private attachments за текущими server/auth boundaries; UI refresh не расширяет видимые данные.
- Демо-карта и демо-оплата остаются явно помеченными и выключенными в production/release.
- Поведенческие тесты не удалять. Если сменился тип контейнера, переводить хрупкий finder на видимый текст, `Key` или semantics, сохраняя исходное бизнес-правило.
- Скриншоты обновляются только существующим Flutter harness. Каждый PNG остаётся 430×932; ссылки в `docs/app-user-paths.html` не подменяются макетами.
- Не изменять пользовательский untracked `docs/APP_WORKFLOW_GUIDE.md`.
- После каждой партии: focused tests → `make mobile-analyze` → `make mobile-screenshots` → визуальный просмотр затронутых PNG → отдельный review. Не начинать следующую партию с Critical или Important замечаниями.
- Checklist 8.2 и HTML `data-status="todo"` остаются открытыми после автономной части: закрытие всё ещё требует MapKit и ручного smoke на реальных iPhone/Android.

## Execution Model

Рекомендуемый режим — `subagent-driven-development`: один implementer на партию, затем отдельные spec-review и code-quality review. Implementer получает только эту задачу, spec и нужные файлы. После исправления всех Critical/Important findings партия коммитится указанным сообщением. Независимые партии не выполняются параллельно, потому что все они меняют общую тему и screenshot artifacts.

---

### Task 1: Onest, theme tokens and five-tab shell

**Files:**

- Create: `mobile/assets/fonts/Onest-Variable.ttf`
- Create: `mobile/assets/fonts/ONEST-OFL.txt`
- Create: `mobile/assets/fonts/ONEST-SOURCE.md`
- Delete: `mobile/assets/fonts/Manrope-Variable.ttf`
- Delete: `mobile/assets/fonts/OFL.txt`
- Modify: `mobile/pubspec.yaml`
- Modify: `mobile/lib/core/theme/app_theme.dart`
- Modify: `mobile/lib/core/router/app_shell.dart`
- Create: `mobile/test/core/theme/app_theme_test.dart`
- Modify: `mobile/test/core/router/app_shell_test.dart`
- Modify: `mobile/tool/capture_client_screenshots_test.dart`
- Modify: `docs/screenshots/*.png`

**Interfaces and exact source:**

- Use release `2.001` from `https://github.com/simpals/onest/releases/download/2.001/onest-2.001.zip`.
- Archive SHA-256: `17b59e19c349e603b7d113a596b6d8e08427e97a7b5235668b69e9d8a06a4267`.
- `fonts/variable/Onest[wght].ttf` SHA-256: `966c5c29b4755da84b6854d5c21dd4eaa2420225d0e9874de602de176d4a9f31`.
- `OFL.txt` SHA-256: `071195d8806e226faeee60259c28ca67b458227af5195a73f5cfcab06e3003bc`.
- Flutter family name is exactly `Onest`; supported app weights are 400, 500, 600, 700 and 800.
- Theme colors and measurements match the approved spec exactly: canvas white, subtle surface `#F7F8F9`, line `#E4E8EB`, control/card/sheet radii 10/12/16, 52 px primary button, no default card shadow, selected navigation icon/label orange and no pill.

- [ ] **Step 1: Add the failing theme contract test**

Create `app_theme_test.dart` and assert that `AppTheme.light()` uses `Onest`, white scaffold/canvas, the approved color values, zero card elevation, 10 px control radius, a transparent navigation indicator and brand-colored selected navigation content. Extend `app_shell_test.dart` to pump `AppTheme.light()` and verify all five destinations still call the supplied index callback.

- [ ] **Step 2: Run the focused test and confirm RED**

Run:

```sh
cd mobile && flutter test test/core/theme/app_theme_test.dart test/core/router/app_shell_test.dart
```

Expected: FAIL on `Manrope`, cloud scaffold, card elevation/border and the Material navigation pill.

- [ ] **Step 3: Vendor and verify Onest**

Download only the pinned release archive to `/private/tmp/sosedi-onest-2.001.zip`, verify the archive hash, extract the variable TTF as `mobile/assets/fonts/Onest-Variable.ttf`, extract the license as `mobile/assets/fonts/ONEST-OFL.txt`, and verify both inner hashes before deleting Manrope files. `ONEST-SOURCE.md` records release URL, upstream commit `8739b1910618a15335e4cc48842052d0ee739ade`, all three hashes, Cyrillic/Latin coverage and SIL OFL 1.1. Do not retain the archive in Git.

- [ ] **Step 4: Implement the minimal theme and shell change**

Update `pubspec.yaml`, both `fontFamily` declarations and the screenshot `FontLoader`. Map the approved type roles onto the existing Material `TextTheme` without letter spacing. Make app/scaffold/app-bar surfaces white, controls subtle, focused fields `brandPressed`, cards flat, dialog radius 16 and navigation indicator transparent. Add a one-pixel top divider around the existing `NavigationBar`; keep its height and five destinations unless 320×720/200% proves a concrete overflow.

- [ ] **Step 5: Confirm GREEN and accessibility safety**

Run:

```sh
cd mobile && flutter test test/core/theme/app_theme_test.dart test/core/router/app_shell_test.dart test/accessibility_test.dart
make mobile-analyze
```

Expected: all pass, no analyzer issues, Russian labels render with the bundled family.

- [ ] **Step 6: Regenerate and inspect the global visual baseline**

Run `make mobile-screenshots`. Inspect all 38 PNGs at original size for missing glyphs, tofu, clipped `₽`, unexpected Material pill, non-white scaffold gaps and low-contrast labels. Run `make app-user-paths-check`.

- [ ] **Step 7: Review and commit**

Run a spec review and code-quality review. Fix all Critical/Important findings, rerun Step 5, then commit:

```text
feat(mobile): establish onest marketplace theme
```

### Task 2: Catalog grid, demo map and favorites

**Files:**

- Modify: `mobile/lib/features/catalog/presentation/catalog_screen.dart`
- Modify: `mobile/lib/features/map/presentation/catalog_map_stub.dart`
- Modify: `mobile/lib/features/favorites/presentation/favorite_button.dart`
- Modify: `mobile/lib/features/favorites/presentation/favorites_screen.dart`
- Modify: `mobile/test/features/catalog/catalog_screen_test.dart`
- Modify: `mobile/test/features/favorites/favorite_button_test.dart`
- Modify: `mobile/test/features/favorites/favorite_screen_test.dart`
- Modify: `docs/screenshots/04-catalog.png`
- Modify: `docs/screenshots/05-map-demo.png`
- Modify: `docs/screenshots/06-item-details.png`
- Modify: `docs/screenshots/29-favorites.png`

**Interfaces:**

- Add `const ValueKey('catalog-grid')` to the result grid so pagination and responsive tests do not depend on `ListView.last`.
- At widths below 600 px, use exactly two columns. Use square 12 px images and increase item extent when text scale exceeds 1.5 so price/title/location remain readable.
- Card order is price → title → area/distance. Condition is omitted when it displaces location. The outer card has no border or shadow.
- Search stays first, 48 px high on subtle surface. Existing date/category/filter/sort/map state and callbacks remain unchanged.

- [ ] **Step 1: Write the failing responsive discovery test**

In `catalog_screen_test.dart`, override the loaded state with two existing `CatalogItem` fixture values and pump it at 320×720 with 200% text. Assert `catalog-grid` exists, its grid delegate resolves to two columns, search remains reachable, two listing semantics are present and `tester.takeException()` is null. Update only the existing pagination finder to target `catalog-grid`; retain the pagination assertion.

- [ ] **Step 2: Run and confirm RED**

Run:

```sh
cd mobile && flutter test test/features/catalog/catalog_screen_test.dart test/features/favorites/favorite_button_test.dart test/features/favorites/favorite_screen_test.dart
```

Expected: the new grid contract fails because catalog and favorites still use vertical card rows.

- [ ] **Step 3: Implement catalog and map styling**

Replace only the loaded list composition with `RefreshIndicator` + scrollable grid/slivers while keeping refresh, error banner, load-more and item navigation calls intact. Build each catalog result as `InkWell` + square clipped image/placeholder + overlay favorite action + flat text column. Restyle search, active filters and the list/map action; keep demo wording. In `catalog_map_stub.dart`, remove decorative card styling from controls and selected item while preserving coarse points and selection callbacks.

- [ ] **Step 4: Implement favorites using the same rules without premature extraction**

Use a local two-column result widget in `favorites_screen.dart`; do not create a shared card for only two consumers. Keep remove-in-place, refresh, error and `/items/:id` navigation behavior. Make `FavoriteButton` a 48×48 high-contrast overlay action with unchanged authentication/toggle semantics.

- [ ] **Step 5: Confirm GREEN and behavior preservation**

Run the Step 2 command, then `make mobile-analyze`. Explicitly verify the existing tests for search, filters, sort, radius permission, area privacy, list↔map restoration, pagination, remove favorite and favorite error rollback still pass.

- [ ] **Step 6: Update and inspect screenshots**

Run `make mobile-screenshots`. Inspect `04-catalog.png`, `05-map-demo.png`, `06-item-details.png` and `29-favorites.png`: two balanced columns, square media, readable prices/titles, 48 px favorite action, no clipped filters, no exact location and clearly labeled demo map. Task 3 will complete the detail hierarchy; in this batch only the shared favorite action may change on `06`. Run `make app-user-paths-check`.

- [ ] **Step 7: Review and commit**

After both reviews and fixes, commit:

```text
feat(mobile): refresh catalog discovery
```

### Task 3: Item details, owner profile, reviews and safety dialog

**Files:**

- Modify: `mobile/lib/features/item/presentation/item_details_screen.dart`
- Modify: `mobile/lib/features/reviews/presentation/owner_profile_screen.dart`
- Modify: `mobile/lib/features/reviews/presentation/review_form_screen.dart`
- Modify: `mobile/lib/features/safety/presentation/report_dialog.dart`
- Modify: `mobile/test/features/item/item_details_screen_test.dart`
- Modify: `mobile/test/features/reviews/review_form_screen_test.dart`
- Modify: `docs/screenshots/06-item-details.png`
- Modify: `docs/screenshots/16-review.png`
- Modify: `docs/screenshots/18-owner-profile.png`

**Interfaces:**

- Preserve `_ItemContent`, `_ItemPrimaryAction`, `_PhotoGallery` and `_DetailRow` responsibilities; do not move data or actions into a new controller.
- Gallery leads, then large price, detail title, flat facts, one tappable owner row, description/safety/rules, then destructive/report actions.
- Bottom CTA remains outside the scrollable body, above safe area, with `const ValueKey('item-primary-action')`.

- [ ] **Step 1: Add the failing small-screen CTA contract**

Extend `item_details_screen_test.dart`: pump a public non-owner item at 320×720 and 200% text, assert no exception, exact address absent, `item-primary-action` visible and tappable, then verify it opens the existing booking route. Keep the existing owner self-booking, legal version, retry and report/block tests unchanged.

- [ ] **Step 2: Run and confirm RED**

Run:

```sh
cd mobile && flutter test test/features/item/item_details_screen_test.dart test/features/reviews/review_form_screen_test.dart
```

Expected: FAIL because the sticky action does not expose the new stable key and the old nested-card hierarchy remains the visual baseline.

- [ ] **Step 3: Flatten item details**

Use 16 px horizontal padding. Remove price capsule and nested bordered cards. Render price with the large-price style before the title; render category, area, condition and completeness as divider-separated fact rows. Replace the rating card plus outline button with one owner `ListTile` containing name, confirmed-rental rating summary and chevron. Keep the public DTO fields exactly as-is. Make safety and availability quiet divider sections; only real errors/warnings use warning color.

- [ ] **Step 4: Align owner/review/safety screens**

Turn owner summary and completed-rental reviews into flat grouped rows. Keep verified-review wording tied to current server data. Simplify review form and report dialog surfaces using the same fields/buttons; do not change required reason, confirmation or submission calls.

- [ ] **Step 5: Confirm GREEN and inspect privacy boundaries**

Run the Step 2 command and `make mobile-analyze`. Confirm all item tests still prove exact address redaction, terminal unavailable state, owner management route, published rules version, retry, item/user report and explicit block confirmation.

- [ ] **Step 6: Update and inspect screenshots**

Run `make mobile-screenshots`; inspect `06`, `16`, `18` for gallery-first hierarchy, one dominant CTA, flat facts, factual trust copy and absence of unsupported verification/payment claims. Run `make app-user-paths-check`.

- [ ] **Step 7: Review and commit**

After both reviews and fixes, commit:

```text
feat(mobile): simplify item detail hierarchy
```

### Task 4: Booking creation, list and lifecycle details

**Files:**

- Modify: `mobile/lib/features/booking/presentation/booking_create_screen.dart`
- Modify: `mobile/lib/features/booking/presentation/booking_list_screen.dart`
- Modify: `mobile/lib/features/booking/presentation/booking_details_screen.dart`
- Modify: `mobile/test/features/booking/booking_screens_test.dart`
- Modify: `docs/screenshots/07-booking-create.png`
- Modify: `docs/screenshots/08-bookings.png`
- Modify: `docs/screenshots/08a-booking-pending-borrower.png`
- Modify: `docs/screenshots/08b-booking-pending-lender.png`
- Modify: `docs/screenshots/09a-booking-confirmed.png`
- Modify: `docs/screenshots/09b-booking-active.png`
- Modify: `docs/screenshots/09c-booking-returned.png`
- Modify: `docs/screenshots/09d-booking-completed.png`
- Modify: `docs/screenshots/09e-booking-cancelled.png`
- Modify: `docs/screenshots/09-payment-demo.png`

**Interfaces:**

- Add `const ValueKey('booking-next-action')` to the server-derived next-action area.
- List rows show thumbnail/placeholder, title, human-readable status, dates and `Беру`/`Сдаю`; compact filters remain scroll-safe.
- In the 1,000+ line details screen, change only presentation helpers such as `_Content`, `_NextActionCard`, `_DemoPaymentCard`, `_Acts` and `_Row`; controllers/state transitions are out of scope.

- [ ] **Step 1: Write the failing next-action accessibility contract**

Change the existing booking next-action test viewport from 430×932 to 320×720 while keeping 200% text. Make it find `booking-next-action`, verify its title and enabled CTA remain reachable without overflow, and assert cancellation reasons are human-readable rather than raw enum codes. Keep both legal acceptance checks in creation tests.

- [ ] **Step 2: Run and confirm RED**

Run:

```sh
cd mobile && flutter test test/features/booking/booking_screens_test.dart test/features/booking/booking_chat_screen_test.dart
```

Expected: FAIL on the missing stable next-action key.

- [ ] **Step 3: Flatten booking creation**

Keep date-first selection and availability calls. Present rental/deposit/total as divider-separated price rows, retain full price disclosure and both exact document checkboxes, and keep submit as the only filled action. Do not hide unavailable/error states or alter request payloads.

- [ ] **Step 4: Convert booking list to compact operational rows**

Replace decorative cards/status capsules with thumbnail rows and status text. Keep lifecycle and role filter callbacks, unread booking-message count and route navigation. Long dates/statuses must wrap without hiding the participant role.

- [ ] **Step 5: Flatten booking details without changing actions**

Lead with status and server-derived next action. Use separate flat sections for dates, price snapshot, handover/contact, acts, support and review. Preserve actor-specific confirm/reject/cancel/no-show/handover behaviors, confirmations, exact-contact visibility, support issue entry and review eligibility. Keep demo payment isolated, explicitly labeled `Демонстрация`, and visually quieter than the real next action.

- [ ] **Step 6: Confirm GREEN and verify lifecycle coverage**

Run Step 2 and `make mobile-analyze`. Ensure the existing PENDING borrower/lender, CONFIRMED, ACTIVE, RETURNED, COMPLETED and CANCELLED tests pass, plus legal gate, price, contact redaction, demo-payment idempotence, cancel confirmation, issue and handover-act tests.

- [ ] **Step 7: Update and inspect screenshots**

Run `make mobile-screenshots`. Inspect all 11 affected booking PNGs at original size and compare lifecycle states side-by-side: status and next action must change clearly while common price/handover sections stay stable. Inspect `09-payment-demo.png` for unmistakable demonstration wording. Run `make app-user-paths-check`.

- [ ] **Step 8: Review and commit**

After both reviews and fixes, commit:

```text
feat(mobile): refresh booking lifecycle screens
```

### Task 5: Booking chat and inbox

**Files:**

- Modify: `mobile/lib/features/booking/presentation/booking_chat_screen.dart`
- Modify: `mobile/lib/features/notifications/presentation/inbox_screen.dart`
- Modify: `mobile/test/features/booking/booking_chat_screen_test.dart`
- Modify: `mobile/test/features/notifications/inbox_screen_test.dart`
- Modify: `docs/screenshots/10-booking-chat.png`
- Modify: `docs/screenshots/13-inbox.png`

**Interfaces:**

- Chat stays text-only with neutral bubbles and a fixed composer. No WebSocket, typing indicator, presence or attachment scope is introduced.
- The fixed composer exposes `const ValueKey('booking-chat-composer')` for compact-screen reachability checks.
- Inbox becomes one divided list. Unread state uses stronger title weight plus a small brand marker, not a filled card.
- Existing event authorization and booking participant checks remain untouched.

- [ ] **Step 1: Add the failing unread/composer semantics checks**

In chat tests, assert `booking-chat-composer` remains visible at 320×720 with 200% text and exposes the existing send action. In inbox tests, assert an unread row has an `Непрочитано` semantic label and opens only its authorized target. Make `_FakeInboxService.markRead()` persist a `singleRead` flag and make the next `listPage()` return the read copy; after opening the target, navigate back to inbox and assert the unread semantic marker is absent. These assertions fail before the new key/semantics are added.

- [ ] **Step 2: Run and confirm RED**

Run:

```sh
cd mobile && flutter test test/features/booking/booking_chat_screen_test.dart test/features/notifications/inbox_screen_test.dart
```

Expected: FAIL because the stable composer key and unread semantic label do not exist yet.

- [ ] **Step 3: Simplify chat surfaces**

Use restrained incoming/outgoing neutral surfaces, readable timestamps/labels and one-pixel separation around the fixed composer. Add the declared stable key to the composer. Preserve loading, pagination, send-disable state, report and block flows. Do not encode participant role by color alone.

- [ ] **Step 4: Convert inbox to grouped rows**

Remove individual bordered cards, add dividers and the unread semantic/visual marker, retain unread filter, load older, mark-all-read and authorized navigation callbacks.

- [ ] **Step 5: Confirm GREEN, update screenshots and inspect**

Run Step 2, `make mobile-analyze`, `make mobile-screenshots` and `make app-user-paths-check`. Inspect `10` and `13` for composer reachability, readable bubble contrast, clear unread state and absence of role-colored decoration.

- [ ] **Step 6: Review and commit**

After both reviews and fixes, commit:

```text
feat(mobile): simplify chat and inbox
```

### Task 6: Three-step listing creation, edit and owned listings

**Files:**

- Modify: `mobile/lib/features/item/presentation/create_item_screen.dart`
- Modify: `mobile/lib/features/item/presentation/edit_item_screen.dart`
- Modify: `mobile/lib/features/item/presentation/owned_items_screen.dart`
- Modify: `mobile/test/features/item/create_item_screen_test.dart`
- Modify: `mobile/test/features/item/edit_item_screen_test.dart`
- Modify: `mobile/test/features/item/owned_items_screen_test.dart`
- Temporarily modify, then restore before commit: `mobile/tool/capture_client_screenshots_test.dart`
- Temporarily create, inspect, then delete: `docs/screenshots/11b-create-item-description.png`
- Temporarily create, inspect, then delete: `docs/screenshots/11c-create-item-location.png`
- Modify: `docs/screenshots/11-create-item.png`
- Modify: `docs/screenshots/12-owned-items.png`
- Modify: `docs/screenshots/17-item-edit.png`

**Interfaces:**

- Creation remains exactly three steps. Header copy is exactly `Шаг 1 из 3`, `Шаг 2 из 3`, `Шаг 3 из 3`; progress is a two-pixel line.
- Step groups are photos; identity/condition/terms; price/location/confirmation. Existing manual coordinates remain visibly temporary and are not normalized as final UX.
- Existing `ItemPhotoPicker`, draft storage, upload/retry, cover/remove actions and controller interfaces remain unchanged.

- [ ] **Step 1: Write the failing three-step behavior contract**

Extend `create_item_screen_test.dart` to assert the new plain step text, photos on step one and preservation of the selected cover while moving forward/back. Retain all permission, corrupt-preview, draft restore, resize/resume and unsaved-changes tests. Verify the two-pixel progress line visually rather than coupling a behavior test to layout thickness.

- [ ] **Step 2: Run and confirm RED**

Run:

```sh
cd mobile && flutter test test/features/item/create_item_screen_test.dart test/features/item/edit_item_screen_test.dart test/features/item/owned_items_screen_test.dart
```

Expected: the new plain step text fails against the current title-suffixed presentation.

- [ ] **Step 3: Restyle creation without refactoring state**

Keep the current controller and form keys. Replace decorative step cards with plain heading, progress line, grouped whitespace and one bottom primary action. Keep photo thumbnails first; place cover marker and remove action on the image with 48 px touch targets. Keep validation and upload failures inline and factual.

- [ ] **Step 4: Align edit and owned listings**

Use the same field grouping and action hierarchy in edit. Convert owned listings to image rows with moderation status as text and one contextual menu/action. Preserve hide confirmation, active-rental conflict, unavailable periods, append-photo behavior and moderation result.

- [ ] **Step 5: Confirm GREEN, update screenshots and inspect**

Run Step 2, `make mobile-analyze` and `make mobile-screenshots`. Inspect `11`, `12`, `17`: photos dominate step one, the progress line is two pixels and visually quiet, no nested card stack, moderation is understandable without raw codes, manual coordinates are clearly temporary. For steps 2 and 3, temporarily register `11b-create-item-description.png` and `11c-create-item-location.png` in the existing screenshot harness: reuse the screenshot photo picker, tap `Далее` for step 2, then patch the existing `FormBuilderState` with valid title/description/category/condition/completeness/handover/price values and tap `Далее` for step 3. Capture both at 430×932, inspect them, then remove the two temporary test registrations and PNG files before running `make app-user-paths-check`; the documented set remains exactly 38.

- [ ] **Step 6: Review and commit**

After both reviews and fixes, commit:

```text
feat(mobile): streamline listing management
```

### Task 7: Profile, privacy and safety settings

**Files:**

- Modify: `mobile/lib/features/profile/presentation/profile_screen.dart`
- Modify: `mobile/lib/features/profile/presentation/profile_edit_screen.dart`
- Modify: `mobile/lib/features/profile/presentation/sessions_screen.dart`
- Modify: `mobile/lib/features/profile/presentation/analytics_settings_screen.dart`
- Modify: `mobile/lib/features/profile/presentation/documents_screen.dart`
- Modify: `mobile/lib/features/profile/presentation/data_export_screen.dart`
- Modify: `mobile/lib/features/profile/presentation/account_closure_screen.dart`
- Modify: `mobile/lib/features/safety/presentation/blocked_users_screen.dart`
- Modify: `mobile/test/features/profile/profile_screen_test.dart`
- Modify: `mobile/test/features/profile/profile_edit_screen_test.dart`
- Modify: `mobile/test/features/profile/sessions_screen_test.dart`
- Modify: `mobile/test/features/profile/analytics_settings_screen_test.dart`
- Modify: `mobile/test/features/profile/documents_screen_test.dart`
- Modify: `mobile/test/features/profile/data_export_screen_test.dart`
- Modify: `mobile/test/features/profile/account_closure_screen_test.dart`
- Modify: `mobile/test/features/safety/blocked_users_screen_test.dart`
- Modify: `docs/screenshots/14-profile.png`
- Modify: `docs/screenshots/19-profile-edit.png`
- Modify: `docs/screenshots/20-sessions.png`
- Modify: `docs/screenshots/21-analytics.png`
- Modify: `docs/screenshots/22-documents.png`
- Modify: `docs/screenshots/23-data-export.png`
- Modify: `docs/screenshots/24-close-account.png`
- Modify: `docs/screenshots/25-blocked-users.png`

**Interfaces:**

- Profile header shows avatar, name, city and factual account/trust status.
- Favorites, sessions, analytics, documents, support, export and blocked users become grouped `ListTile` rows with dividers and unchanged route targets.
- The navigation section exposes `const ValueKey('profile-navigation-group')`; its child type is not part of the test contract.
- Account closure remains a separate destructive text action and retains all confirmation/blocker behavior.

- [ ] **Step 1: Write the failing grouped-navigation test**

Extend `profile_screen_test.dart` to expect `profile-navigation-group` plus the visible destinations `Избранное`, `Устройства и сессии`, `Правила и документы`, `Поддержка`, `Экспортировать мои данные` and `Заблокированные пользователи`; do not assert a concrete row widget type. Pump the screen with a small `GoRouter` whose existing destination paths render text sentinels; tap `Избранное` and `Поддержка` and verify those sentinels. The test must still assert only the authenticated user profile is shown.

- [ ] **Step 2: Run and confirm RED**

Run:

```sh
cd mobile && flutter test test/features/profile/profile_screen_test.dart test/features/profile/profile_edit_screen_test.dart test/features/profile/sessions_screen_test.dart test/features/profile/analytics_settings_screen_test.dart test/features/profile/documents_screen_test.dart test/features/profile/data_export_screen_test.dart test/features/profile/account_closure_screen_test.dart test/features/safety/blocked_users_screen_test.dart
```

Expected: FAIL because the stable navigation-group key does not exist yet.

- [ ] **Step 3: Build the flat profile hierarchy locally**

Replace the warm hero card and repeated outline buttons with a flat header and local grouped sections. Add the declared key to the navigation section; do not extract a generic settings package. Use section labels, dividers and chevrons; keep exact route strings and edit action. Display KYC/account wording only from existing status data and do not imply verification beyond it.

- [ ] **Step 4: Align privacy and safety sub-screens**

Apply the same flat rows/fields/bottom actions to edit, sessions, analytics, documents, export and blocked users. Preserve avatar quarantine flow, session revoke/current/all behavior, consent default-off/revoke, fail-closed legal URLs and fresh-OTP purpose-bound export. On account closure, keep consequences, blocker, checkbox/confirmation, request state and cancel flow; use red only for the destructive text/action.

- [ ] **Step 5: Confirm GREEN, update screenshots and inspect**

Run Step 2, `make mobile-analyze`, `make mobile-screenshots` and `make app-user-paths-check`. Inspect `14` and `19–25` for a consistent grouped hierarchy, factual privacy text, visible destructive separation and no hidden blocker/confirmation.

- [ ] **Step 6: Review and commit**

After both reviews and fixes, commit:

```text
feat(mobile): simplify profile and privacy screens
```

### Task 8: Onboarding, OTP auth, support and update-required state

**Files:**

- Modify: `mobile/lib/features/auth/presentation/onboarding_screen.dart`
- Modify: `mobile/lib/features/auth/presentation/phone_screen.dart`
- Modify: `mobile/lib/features/auth/presentation/otp_screen.dart`
- Modify: `mobile/lib/features/support/presentation/support_screen.dart`
- Modify: `mobile/lib/features/support/presentation/support_ticket_screen.dart`
- Modify: `mobile/lib/core/compatibility/update_required_screen.dart`
- Modify: `mobile/test/features/auth/auth_screens_test.dart`
- Modify: `mobile/test/features/support/support_screen_test.dart`
- Modify: `mobile/test/core/compatibility/update_required_screen_test.dart`
- Modify: `mobile/test/core/router/app_router_test.dart`
- Modify: `mobile/test/widget_test.dart`
- Modify: `docs/screenshots/01-onboarding.png`
- Modify: `docs/screenshots/01b-onboarding-trust.png`
- Modify: `docs/screenshots/01c-onboarding-search.png`
- Modify: `docs/screenshots/02-phone-login.png`
- Modify: `docs/screenshots/03-otp.png`
- Modify: `docs/screenshots/15-support.png`
- Modify: `docs/screenshots/26-support-export.png`
- Modify: `docs/screenshots/27-support-ticket.png`
- Modify: `docs/screenshots/28-update-required.png`

**Interfaces:**

- Auth/onboarding keep one message and one primary action per state, existing skip/next/public-catalog behavior and return-to intent.
- Phone/OTP validation, loading, error and resend/verify calls are unchanged.
- Support retains GENERAL tickets, private photo path, closed read-only state, export prefill and thread send behavior.
- Update-required remains fail-closed with one trusted-store CTA.
- Phone and OTP primary buttons expose `const ValueKey('auth-primary-action')`; the support form submit exposes `const ValueKey('support-primary-action')`.

- [ ] **Step 1: Add the failing 200% auth/support reachability tests**

In auth tests, pump phone and OTP at 320×720/200%, enter valid values and assert `auth-primary-action` remains visible and no exception occurs. In support tests, do the same for subject/message and `support-primary-action`. Keep router tests for guest browse, cancel and post-auth resume.

- [ ] **Step 2: Run and confirm RED**

Run:

```sh
cd mobile && flutter test test/features/auth/auth_screens_test.dart test/features/support/support_screen_test.dart test/core/compatibility/update_required_screen_test.dart test/core/router/app_router_test.dart test/widget_test.dart
```

Expected: FAIL because the stable primary-action keys do not exist yet.

- [ ] **Step 3: Simplify onboarding and auth**

Keep all three onboarding messages but remove decorative feature-card styling; use one code-native icon, concise copy, progress and one primary action. Make phone and OTP screens one-column forms with subtle fields and one bottom action, add the declared stable key to each primary button, and preserve country normalization, loading disable state, errors and return-to behavior.

- [ ] **Step 4: Align support and update gate**

Use the common field and bottom-action hierarchy in support and add the declared stable key to its submit button. Make ticket history a divided thread with neutral user/support alignment and labels; preserve private attachment and closed-ticket rules. Keep update-required centered on one explanation and trusted CTA without extra decoration.

- [ ] **Step 5: Confirm GREEN, update screenshots and inspect**

Run Step 2, `make mobile-analyze`, `make mobile-screenshots` and `make app-user-paths-check`. Inspect `01–03`, `15`, `26–28` for single-action focus, input/keyboard reachability, clear demo/system wording and no invented legal or trust claims.

- [ ] **Step 6: Review and commit**

After both reviews and fixes, commit:

```text
feat(mobile): refresh auth and support screens
```

### Task 9: Full visual audit, application map and source-of-truth sync

**Files:**

- Modify: `mobile/tool/capture_client_screenshots_test.dart` only if fixture/capture defects remain
- Modify: `docs/screenshots/*.png`
- Modify: `docs/screenshots/README.md`
- Modify: `docs/app-user-paths.html`
- Modify: `MVP_CHECKLIST.md`
- Modify: `sosedi-roadmap.html`
- Do not modify: `.codex/HANDOFF.md` while checklist 8.2 remains open

**Acceptance matrix:**

- 38/38 route/state PNG files render from Flutter widgets at 430×932 and all are referenced by the application map.
- Catalog, item sticky CTA, booking next action, phone/OTP and support submit pass 320×720 at 200% text without overflow or unreachable actions.
- Russian Cyrillic, `₽`, dates, weights 400/500/600/700/800 and Material icons render correctly from bundled assets.
- No app screen uses Manrope, default navigation pill, numbered documentation styling, orange full-card fill, unnecessary status capsule, gradient or shadowed card stack.
- Existing guest/auth/privacy/legal/booking fail-closed tests remain green.

- [ ] **Step 1: Run static contract scans**

Run:

```sh
rg -n "Manrope|fontFamilyFallback:.*Inter" mobile/lib mobile/pubspec.yaml mobile/tool mobile/assets
rg -n "LinearGradient|RadialGradient|SweepGradient" mobile/lib
rg -n "elevation:\s*[1-9]|BoxShadow" mobile/lib/features mobile/lib/core/theme
```

Expected: first command has no matches; gradients have no matches; any nonzero modal/FAB elevation is individually justified by the approved spec and no ordinary content card has a shadow.

- [ ] **Step 2: Run the complete automated suite**

Run in order:

```sh
make mobile-analyze
make mobile-test
make mobile-screenshots
make app-user-paths-check
```

Expected: every command exits 0; screenshot verifier reports 38 files and no missing/unreferenced PNG.

- [ ] **Step 3: Inspect all screenshots by user path**

Review at original size in this order: first entry `01–04`; borrower `05–10`, `16`, `18`, `29`; lender `11`, `12`, `17`; inbox/profile/support `13–15`, `19–27`; system `28`. Confirm Task 6 also inspected temporary 430×932 captures of listing steps 2 and 3 before deleting them. Compare consecutive booking lifecycle screenshots side-by-side. Record and fix every overflow, hidden action, inconsistent radius/spacing, raw enum, low contrast, unsupported claim or obsolete decorative card, then rerun Steps 1–2.

- [ ] **Step 4: Verify compact/high-text states**

Run the focused widget tests containing 320×720/200% cases:

```sh
cd mobile && flutter test test/features/catalog/catalog_screen_test.dart test/features/item/item_details_screen_test.dart test/features/booking/booking_screens_test.dart test/features/booking/booking_chat_screen_test.dart test/features/auth/auth_screens_test.dart test/features/support/support_screen_test.dart
```

Expected: no render overflow and each primary/next action remains reachable.

- [ ] **Step 5: Synchronize screenshot documentation**

Update `docs/screenshots/README.md` to state that the 30.08.2026 set uses bundled Onest 2.001 and the approved flat marketplace hierarchy. Update the short introduction/captions in `docs/app-user-paths.html` where the old one-column/catalog-card wording no longer matches. Do not add numbers, connector dots or `Готово` badges back to the visible map. Run `make app-user-paths-check` again.

- [ ] **Step 6: Record autonomous completion without closing external gates**

Append this factual note to the existing open checklist 8.2 item and mirror it in the existing HTML todo item: bundled Onest, nine visual batches, two-column catalog, flat details/rows, 38 regenerated screenshots and all four verification commands passed; MapKit and real iPhone/Android visual smoke remain. Keep `[ ]`, `data-status="todo"`, total count and percentage unchanged. Do not rewrite `.codex/HANDOFF.md`, because no checklist checkbox is closed.

- [ ] **Step 7: Final review and commit**

Request one final full-diff spec review and one code-quality/accessibility review. Fix all Critical/Important findings, rerun Steps 1–4, then confirm `git status --short` contains only declared work plus the untouched user-owned `?? docs/APP_WORKFLOW_GUIDE.md`. Commit:

```text
docs(mobile): publish refreshed application map
```

## Definition of Done

- Every task commit exists in order and contains only its declared scope plus regenerated affected PNGs.
- `make mobile-analyze`, `make mobile-test`, `make mobile-screenshots` and `make app-user-paths-check` pass on the final tree.
- All 38 screenshots are real Flutter captures, visually reviewed and linked.
- The app uses only bundled Onest 2.001 for its interface family.
- No REST/FSM/auth/legal/privacy behavior changed.
- Checklist 8.2 truthfully records autonomous UI completion and remains open only for its documented MapKit/device gates.
