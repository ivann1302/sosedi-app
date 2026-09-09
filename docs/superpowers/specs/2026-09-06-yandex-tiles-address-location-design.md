# Sosedi low-cost location input design

**Date:** 2026-09-06  
**Status:** approved  
**Roadmap owner:** `MVP_CHECKLIST.md`, sections 8.2, 9 and 12

## Goal

Use one low-cost map provider for listing location: Yandex Tiles API supplies
the map background and `flutter_map` supplies interaction and markers. Keep
address entry clear and usable without another paid provider.

## User experience

The listing form contains the public `Район` field and private
`Адрес передачи` field. Both accept normal text. The owner can mark or correct
the exact handover point on the map when a Tiles key is available. The form
never asks for latitude or longitude.

The point picker opens at the saved point or Moscow, places one marker on tap,
and offers `Моё местоположение`. It always shows the official clickable Yandex
logo in a map corner. Without a Tiles key, the manual fields remain available
and the map action is hidden. Exact address and coordinates remain private under
the existing API rules.

## Architecture

Mobile uses pinned `flutter_map` and `latlong2` packages. The Tiles API key is
read from `--dart-define=YANDEX_TILES_API_KEY=...`; it is never stored in Git.
The tile URL explicitly requests `projection=web_mercator`, matching
`flutter_map`. MapKit initialization, lifecycle code, CocoaPods workaround and
Android lifecycle override are removed.

The create/update item REST payload remains unchanged. The manual form fields
write the existing address and area values, and the picker writes the existing
`GeoPoint`. No address-suggestion endpoint, DTO or provider key is required.

## Privacy and failure behavior

- The app does not send typed addresses to a separate suggestion provider.
- Tile requests contain only the data required by the Tiles API.
- Provider outages do not erase form values.
- The encrypted local listing draft continues to omit exact address and point.
- Public listing APIs continue to expose only district and stable coarse point.
- Consent/legal text must disclose the tile provider before a public release.

## Cost and operational limits

Yandex Tiles API is free for commercial and non-commercial use up to 30 requests
per second under its current terms. The app uses no separate address API, yearly
address-provider subscription or MapKit DAU tariff.

## Verification

- Map configuration tests cover the exact Web Mercator tile URL and missing-key
  fail-closed behavior.
- Listing widget tests cover manual address input and point selection.
- Android keyed smoke covers real tiles, attribution, marker and confirmation.
- `make backend-lint`, `make backend-test`, `make backend-build`,
  `make mobile-analyze`, `make mobile-test`, Android debug build and
  `git diff --check` pass.

## Sources

- Yandex Tiles API: https://yandex.ru/maps-api/products/tiles-api
- Yandex Tiles requirements: https://yandex.ru/maps-api/docs/tiles-api/index.html
- flutter_map 8.3.2: https://pub.dev/packages/flutter_map/versions/8.3.2
