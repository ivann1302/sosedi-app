# Sosedi Mobile

Flutter client for the Sosedi P2P item-rental MVP.

The implemented mobile surface contains onboarding, SMS OTP/session management,
profile/edit/closure, catalog and item details, owner listing creation/edit/
calendar, participant bookings with handover/return acts, support, UGC safety
and the in-app inbox. Private photos use the backend presign → quarantine →
confirm flow. Map/provider push, payment/dispute and KYC production flows remain
behind their explicit checklist gates and must not be presented as ready.

One `USER` account supports both product scenarios: borrowing another user's
item and lending an owned item. The UI must not ask the user to choose a
permanent borrower/lender role.

## Run

From the repository root:

```bash
make mobile-gen
cd mobile
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Android Emulator uses `http://10.0.2.2:3000/api/v1` by default when
`API_BASE_URL` is omitted in local/debug. Release runtime requires
`APP_ENVIRONMENT=production` and a public HTTPS API ending in `/api/v1`.

The listing point picker uses Yandex Tiles API only when a key is supplied at
build time. Release wrappers and the manual CI smoke read
`YANDEX_TILES_API_KEY` from the environment and pass it through a private
temporary `--dart-define-from-file` file. From the repository root, with the
environment already configured:

```bash
make mobile-tiles-smoke
```

Do not write the key to Git. Without it the app keeps manual address entry
available and hides the map action. The owner enters the public district and
private handover address manually, then optionally marks the exact point on the
map. Latitude and longitude are never shown in the form.

The smoke builds a debug APK, does not publish it, and does not verify live
Tiles requests. See [Tiles CI setup](../docs/mobile-tiles-ci.md) for the protected
GitHub environment, local fixture smoke and remaining provider/store gates.

## Production release config

Booking submit stays disabled unless the four offer/rental-rules compile-time
values are valid:

- `MARKETPLACE_OFFER_VERSION` and its versioned HTTPS
  `MARKETPLACE_OFFER_URL`;
- `MARKETPLACE_CANCELLATION_POLICY_VERSION` and its versioned HTTPS
  `MARKETPLACE_RENTAL_RULES_URL`.

The profile shows the published document set only when the additional
`MARKETPLACE_PRIVACY_VERSION` and versioned HTTPS
`MARKETPLACE_PRIVACY_URL` are also valid.

Before a release build, export those values together with production
`API_BASE_URL`, `APP_ENVIRONMENT=production`, `APP_RELEASE` and the full
`RELEASE_COMMIT_SHA`, then run
`make mobile-android-release` or `make mobile-ios-release` from the repository
root. The wrapper validates the values, enforces the committed Dart/CocoaPods
locks, requires that `RELEASE_COMMIT_SHA` equals a clean Git HEAD and passes that
exact public config to Flutter as `--dart-define`. After a successful build it
writes `sosedi-release-manifest.json` beside the AAB/IPA with the artifact
SHA-256, source commit and public config; the manifest contains no credentials
and is retained with protected release evidence. Before upload,
run `MOBILE_RELEASE_MANIFEST_PATH=... make mobile-release-artifact-verify` with
the same environment to reject changed bytes, a different commit/config or path
traversal.

Android release never falls back to the debug key. The wrapper requires
gitignored `android/key.properties` and its keystore to be owner-only regular
files; see `docs/store-readiness.md`. Missing production signing assets block the
build.

`APP_RELEASE` must be `sosedi@MAJOR.MINOR.PATCH+BUILD`; the wrapper derives
Flutter `--build-name` and numeric `--build-number` from it, so package metadata,
GlitchTip release and checksum manifest cannot silently diverge.

iOS release requires `IOS_DEVELOPMENT_TEAM` and an owner-only
`IOS_EXPORT_OPTIONS_PLIST` whose `teamID` matches and whose method is
`app-store-connect`. The plist path is passed to Flutter explicitly; missing
Apple signing assets still block the archive/export.

`make mobile-release-config` is the non-building preflight. Missing, draft,
insecure, loopback/IP/reserved-host or mismatched values fail before build tools
run.

## Checks

Run from the repository root:

```bash
make mobile-analyze
make mobile-test
```

## Structure

```text
lib/core/      Network, router, storage, theme and observability
lib/features/  Feature-based UI, providers and services
lib/shared/    Shared immutable models
```

The dependency flow is `UI -> Provider -> Service -> API`. State uses Riverpod,
navigation uses GoRouter and HTTP uses Dio. DTO use Freezed with generated JSON
serialization.

GlitchTip is enabled only with a self-hosted HTTPS `GLITCHTIP_DSN`; hosted
`sentry.io` is rejected and sensitive event fields are removed before sending.
