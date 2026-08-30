# Final fix report — accessible marketplace tokens and catalog mechanics

**Date:** 2026-08-30
**Status:** DONE

## Scope and assumptions

- Kept REST contracts, providers, booking/payment FSM, authorization, legal
  gates and public-location behavior unchanged.
- Treated default sort, null category, absent dates/area/radius/price as
  inactive. The first catalog row therefore keeps one always-visible filter
  trigger and renders summaries only for non-default selections.
- Kept checklist 8.2 open and did not touch `.codex/HANDOFF.md` or the
  main-checkout user file `docs/APP_WORKFLOW_GUIDE.md`.

## RED

The first focused run added real component/theme and catalog behavior tests,
then failed for the intended reasons:

- selected navigation foreground measured **2.006:1** on white;
- focused input boundary measured **2.222:1** on cloud;
- auth/onboarding titles resolved to weight 800 instead of 700;
- the default catalog row exposed inactive dates, category and sort controls;
- null `Все категории` was selected;
- search had no component-local cloud/no-outline contract;
- sheet-based category/sort callbacks could not satisfy the new row behavior.

The original RED run reported 11 failures. A separate visual RED regression
also caught Material's default white selected-chip checkmark on warm selection.

## GREEN implementation

- Added `brandForeground = #B65700` for selected navigation foreground and
  focus boundaries. Its contrast is **4.825:1 on #FFFFFF** and **4.538:1 on
  #F7F8F9**. `brand500` remains the filled CTA, progress and quiet non-text cue.
- Navigation has no pill; selected icon/label use `brandForeground`, and all
  navigation labels use approved weight 600.
- Global chips use cloud when unselected, warm sand when selected, and ink for
  labels, icons and checkmarks.
- Catalog search is 48 px on cloud with no resting outline and the accessible
  two-pixel focus boundary.
- The default filter row contains only `Фильтры`. Dates, categories, sort,
  area, price and radius remain reachable in one scrollable sheet. Non-default
  choices become removable warm summaries; null `Все категории` is never
  selected. Existing search, callbacks, pagination and list/map state remain
  covered by the catalog tests.
- Auth/onboarding/home titles now use the 24/30 weight-700 role without
  changing the 24/30 weight-800 large-price role.
- Booking-chat and create-listing literal colors now use `AppColors` tokens.
- The application-map note now documents backend-controlled exact contact and
  address access for `CONFIRMED`, `ACTIVE` and `RETURNED` through the handover,
  return and dispute window, with immediate revocation on `CANCELLED` and no
  exact public location.

## Files

- Theme/auth/catalog/chat/listing source and focused tests under `mobile/`.
- Approved design contract:
  `docs/superpowers/specs/2026-08-30-avito-inspired-sosedi-mobile-design.md`.
- Privacy lifecycle note: `docs/app-user-paths.html`.
- Thirteen regenerated 430×932 PNGs: `01`, `01b`, `01c`, `02`, `03`, `04`,
  `05`, `08`, `10`, `11`, `12`, `13`, and `14`.

## Verification

- Focused theme/shell/accessibility/auth/catalog GREEN: 38/38.
- Affected booking-chat/create-listing GREEN: 17/17.
- Post-visual chip/theme/accessibility/catalog/booking GREEN: 42/42.
- Exact scans: no Manrope/Inter fallback; no gradients; only the spec-allowed
  FAB `elevation: 2` match and no ordinary content-card shadow.
- `make mobile-analyze`: `No issues found`.
- `make mobile-test`: 269/269.
- `make mobile-screenshots`: 38/38 captures regenerated.
- `make app-user-paths-check`: `references=40, files=38`.
- Exact Task 9 compact six-file suite: 70/70.
- All 13 changed PNGs were inspected at original 430×932. `04-catalog.png`
  has one unclipped filter trigger; all five shell destinations were checked in
  `04`, `08`, `12`, `13`, and `14`; the selected navigation state is readable
  and has no pill. The booking lifecycle PNGs have no diff.

## Concerns

- No remaining code or screenshot concern found in this wave.
- Checklist 8.2 intentionally remains open for production MapKit and manual
  visual smoke on real iPhone/Android hardware.

## Minor closure round — live catalog filters

### RED

Two new assertions failed for the intended review findings:

- the exact 13/18 `labelSmall` theme role returned weight 500 instead of 600;
- a filter sheet opened while `catalogCategoriesProvider` was pending kept its
  progress indicator after the provider completed, because the modal retained
  the opening `AsyncValue` snapshot.

### GREEN

- `labelSmall` now uses the approved 13/18 weight-600 contract. This also keeps
  chat metadata on the approved label role.
- The modal contains a narrow `Consumer` that watches
  `catalogCategoriesProvider`; loading, error/retry and data now update in the
  already-open sheet. Filter state, callbacks and sheet controls are unchanged.
- The focused theme/catalog suite passes 23/23; the related
  theme/catalog/accessibility/chat suite passes 31/31.

### Fresh verification

- `make mobile-analyze`: `No issues found`.
- `make mobile-test`: 270/270.
- `make mobile-screenshots`: 38/38 captures regenerated; only
  `10-booking-chat.png` changed and was inspected at original 430×932 with no
  clipping or hierarchy regression.
- `make app-user-paths-check`: `references=40, files=38`.
- Exact Task 9 compact six-file suite: 71/71.
- Exact font/gradient scans have no matches; the shadow scan still has only the
  approved FAB `elevation: 2` match.
- Checklist 8.2 remains open; `.codex/HANDOFF.md` and the main-checkout user
  file remain untouched.
