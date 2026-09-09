# Sosedi catalog map clusters and pilot photos design

**Date:** 2026-09-07  
**Status:** approved  
**Roadmap owner:** `MVP_CHECKLIST.md`, sections 8.2 and 9

## Goal

Make the Android catalog map use the available phone viewport efficiently,
cluster nearby public coarse points and show a photo-first item card only after
the user selects a marker. Add realistic generated photos to the local pilot
fixtures without adding a test CDN.

## User experience

The bottom application navigation stays visible. In map mode, the map fills the
remaining area below the compact search and filters. A small notice says that
locations are approximate; the required clickable Yandex logo remains visible.

No item is selected when the map first opens. Tapping a marker shows one compact
bottom card with the cover photo, title, daily price and area. The entire card
opens the item. A close button or a tap on empty map space hides it. Nearby
markers form an orange count cluster; tapping the cluster zooms until its items
separate.

All seven local pilot listings, including the pending owner listing, receive
consistent, photorealistic product photos. The same photos appear in catalog,
map, favorites, owned listings and item details.

## Architecture

Keep the existing `flutter_map: 8.3.2` and `latlong2: 0.10.1`. A small local
screen-grid cluster layer groups the current page of markers and fans out
coincident coarse points after a cluster tap. `CatalogMap` owns no catalog query
state: it receives items and nullable selection callbacks from `CatalogScreen`.

Generated photos live in `mobile/assets/images/mock_items/`. The development-only
pilot seed exposes them through existing photo URL fields with the
`asset:///assets/images/mock_items/...` scheme. A small shared `ItemPhotoImage`
widget resolves this scheme to `Image.asset` and keeps HTTPS/HTTP photos on
`Image.network`. No production API field or storage provider changes.

## Scope decision

`Искать в этой области` is removed from MVP scope. Manual area filtering remains.
Current-position and radius behavior remain separate gated work.

## Accessibility and failure behavior

- Marker, cluster, close and card actions have Russian semantic labels.
- The selected card stays within a 320×720 viewport at 200% text.
- Missing or failed images use the existing neutral item placeholder.
- Exact pickup address and exact coordinates remain absent from the public UI.
- Without a Tiles key, the map action remains hidden.

## Verification

- Widget tests cover initially hidden selection, marker selection, closing,
  full-card navigation, clustering and compact 200% layout.
- Seed tests cover one deterministic generated cover per pilot fixture.
- Analyzer, mobile tests, relevant backend tests, Android debug build and a
  physical Samsung smoke pass.

## Dependency decision

`flutter_map_marker_cluster 8.2.2` was evaluated but rejects the project's pinned
`latlong2 0.10.1` because it requires `latlong2 ^0.9.1`. The local layer avoids a
downgrade and keeps the clustering scope limited to the current page of at most
50 catalog items.
