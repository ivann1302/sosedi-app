# Yandex Tiles and manual address implementation plan

**Goal:** Use Yandex Tiles for the listing point picker while keeping district
and private address entry manual, friendly and independent of another provider.

**Architecture:** Flutter writes the existing address/area values and
`GeoPoint` directly into the unchanged listing API contract. A pinned
`flutter_map` client loads Web Mercator tiles when a Tiles key is configured.

**Spec:** `docs/superpowers/specs/2026-09-06-yandex-tiles-address-location-design.md`

## Constraints

- Keep exact address and coordinates out of public responses and local drafts.
- Keep the Tiles key outside Git.
- Keep manual address entry available without the map.
- Show the official clickable Yandex logo over every Tiles API map.
- Do not add a second address provider or provider abstraction.

## Task 1: Replace native MapKit with Yandex Tiles

- [x] Add pinned `flutter_map: 8.3.2` and `latlong2: 0.10.1`.
- [x] Read `YANDEX_TILES_API_KEY` from `--dart-define`.
- [x] Implement Web Mercator tiles, tap marker, current location, attribution
  and missing-key fallback.
- [x] Remove MapKit lifecycle and platform setup.
- [x] Pass configuration tests, analyzer, Android build and keyed device smoke.

## Task 2: Keep location entry simple

- [x] Keep `Район` and `Адрес передачи` as normal manual fields.
- [x] Keep exact point selection as an independent map action.
- [x] Remove latitude/longitude fields from the user interface.
- [x] Remove the external address-suggestion endpoint, mobile client, tests and
  secret.
- [x] Confirm that public DTO and encrypted draft privacy boundaries are
  unchanged.

## Task 3: Unify form selection controls and catalog density

- [x] Add one shared inline select control that expands only downward inside
  the form.
- [x] Replace active dropdown fields in listing, catalog, booking, review and
  report flows.
- [x] Fit four complete catalog cards above phone navigation at 360×800.
- [x] Cover the downward layout and four-card viewport with focused widget
  regression tests.

## Task 4: Synchronize project truth and verify

- [x] Update `MVP_CHECKLIST.md`, `sosedi-roadmap.html`,
  `OWNER_ACTIONS.md` and `mobile/README.md`.
- [x] Run backend lint/test/build, mobile analyze/test, Android debug build and
  `git diff --check`.
- [x] Rewrite `.codex/HANDOFF.md` with the exact next checklist item.
