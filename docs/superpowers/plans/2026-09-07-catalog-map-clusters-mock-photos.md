# Catalog map clusters and pilot photos implementation plan

> **For agentic workers:** Execute inline in this session. Steps use checkbox
> (`- [x]`) syntax for tracking; do not commit from the shared dirty worktree.

**Goal:** Deliver the approved full-height phone map, clustered public markers,
selection-only photo card and generated photos for all local pilot listings.

**Architecture:** `CatalogScreen` retains shared list/map state and passes a
nullable selection into `CatalogMap`. A small local screen-grid layer clusters
the current page of coarse points and fans out coincident points. Pilot photos use existing DTO URL fields plus one shared resolver
for bundled `asset:///` images and normal network URLs.

**Tech Stack:** Flutter 3, Dart 3, flutter_map 8.3.2, latlong2 0.10.1,
Flutter widget tests, NestJS/Prisma seed tests.

**Spec:** `docs/superpowers/specs/2026-09-07-catalog-map-clusters-mock-photos-design.md`

## Global Constraints

- Keep bottom navigation visible and exact locations private.
- Keep search, filters and list/map state shared.
- Do not add `Искать в этой области` to the MVP.
- Use exactly one compact selected-item card and open it by tapping the card.
- Keep generated assets local and pilot-only; do not add a test CDN.
- Modify only files needed for this slice and preserve unrelated dirty changes.

---

### Task 1: Lock the map interaction contract with widget tests

**Files:**
- Modify: `mobile/test/features/catalog/catalog_screen_test.dart`

**Interfaces:**
- Consumes: `CatalogScreen`, `CatalogMap`, `CatalogItem`.
- Produces: regression expectations for nullable selection and clustered markers.

- [x] Add a test asserting `catalog-map-selected-*` is absent immediately after
  switching to the map.
- [x] Add a test that taps a marker, finds a photo-first card, taps empty map
  space and verifies the card closes.
- [x] Add a navigation test that taps the whole selected card rather than an
  `Открыть` button.
- [x] Add overlapping fixture points and assert a count cluster is rendered and
  its tap increases map zoom.
- [x] Keep the 320×720 at 200% text regression and assert no exception.
- [x] Run `flutter test test/features/catalog/catalog_screen_test.dart` and
  confirm the new expectations fail before implementation.

### Task 2: Implement the approved clustered map

**Files:**
- Modify: `mobile/pubspec.yaml`
- Modify: `mobile/pubspec.lock`
- Modify: `mobile/lib/features/catalog/presentation/catalog_screen.dart`
- Modify: `mobile/lib/features/map/presentation/catalog_map.dart`

**Interfaces:**
- Consumes: `List<CatalogItem>`, `String? selectedItemId`, Yandex tile key.
- Produces: `ValueChanged<String?> onItemSelected` and map/card interactions.

- [x] Keep existing map dependencies and add a local screen-grid cluster layer
  for the current page of at most 50 items.
- [x] Remove the first-item selection fallback and render the bottom card only
  when `selectedItemId` matches an item.
- [x] Render orange count clusters, zoom on tap and fan out coincident coarse
  points so every item remains selectable.
- [x] Clear selection from `MapOptions.onTap` and from the card close action.
- [x] Remove outer map padding, keep compact attribution/privacy overlays and
  preserve the application bottom navigation.
- [x] Make the entire photo-first card navigate to `/items/{id}`.
- [x] Run the focused catalog tests until green.

### Task 3: Generate and connect local pilot product photos

**Files:**
- Create: `mobile/assets/images/mock_items/projector.jpg`
- Create: `mobile/assets/images/mock_items/camera.jpg`
- Create: `mobile/assets/images/mock_items/game-console.jpg`
- Create: `mobile/assets/images/mock_items/board-game.jpg`
- Create: `mobile/assets/images/mock_items/acoustic-guitar.jpg`
- Create: `mobile/assets/images/mock_items/sewing-machine.jpg`
- Create: `mobile/assets/images/mock_items/projector-screen.jpg`
- Create: `mobile/lib/shared/widgets/item_photo_image.dart`
- Create: `mobile/test/shared/widgets/item_photo_image_test.dart`
- Modify: `mobile/pubspec.yaml`
- Modify: `backend/src/operations/local-pilot-seed.ts`
- Modify: `backend/src/operations/local-pilot-seed.spec.ts`
- Modify: catalog, favorites, owned-item and item-details photo call sites.

**Interfaces:**
- Consumes: existing `thumbnailUrl`/`previewUrl` strings.
- Produces: `ItemPhotoImage(source: String, semanticLabel: String, fit: BoxFit)`.

- [x] Generate seven square, photorealistic, unbranded product photos with no text,
  watermark or people; save optimized JPEG files under `mock_items`.
- [x] Add the asset directory to `pubspec.yaml`.
- [x] First add a failing widget test that expects `asset:///...` to build an
  `AssetImage` and an ordinary HTTPS source to build a `NetworkImage`.
- [x] Implement `ItemPhotoImage` with an allowlisted mock-asset prefix and the
  existing neutral error placeholder.
- [x] Replace direct item `Image.network` call sites with the shared widget.
- [x] Add stable `photoId`/`photoAsset` values to every pilot fixture and upsert
  one cover `ItemPhoto` through existing URL fields.
- [x] Add a seed regression assertion for six approved covers plus the pending
  fixture cover, then run the relevant backend test.

### Task 4: Remove deferred area-map search and verify the slice

**Files:**
- Modify: `MVP_CHECKLIST.md`
- Modify: `sosedi-roadmap.html`
- Modify: `README.md`
- Modify: `docs/app-user-paths.html`
- Modify: `docs/screenshots/05-map.png`
- Modify: `.codex/HANDOFF.md`

**Interfaces:**
- Consumes: completed device behavior and verification output.
- Produces: synchronized project truth and handoff.

- [x] Remove `Искать в этой области` from MVP scope while retaining manual area
  filtering and its empty state.
- [x] Record the clustered full-height map and generated pilot covers without
  changing unrelated checklist status.
- [x] Run `make mobile-analyze`, `make mobile-test`, the relevant backend seed
  test, `make app-user-paths-check` and `git diff --check`.
- [x] Build the keyed Android debug APK, install it on the connected Samsung and
  smoke map clustering, selection, closing, item opening and visible photos.
- [x] Capture the current map screenshot and rewrite `.codex/HANDOFF.md` within
  its eight-line/800-character limit.
