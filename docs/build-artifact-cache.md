# Build artifact cache

CI caches are an acceleration layer and never replace lock-files, pinned
container digests or the Russian production registry.

| Artifact | Cache key / source of truth | Verification |
| --- | --- | --- |
| Backend npm downloads | `backend/package-lock.json` via `setup-node` | `npm ci` |
| Operator npm downloads | `operator/package-lock.json` via `setup-node` | `npm ci` |
| Flutter SDK and pub packages | Flutter 3.44.7 + `mobile/pubspec.lock` | `flutter pub get --enforce-lockfile` |
| Prisma generated client | OS + Node 22 + backend lock + Prisma schema | `npx prisma generate` on cache miss, then backend build/tests |
| CocoaPods downloads and `Pods` | OS + `mobile/ios/Podfile.lock` | `pod install --deployment` and unsigned release build |

The iOS smoke job runs on macOS and produces no signed artifact. It proves that
the locked Flutter/CocoaPods graph compiles before signing and TestFlight
credentials exist; it does not close the Store readiness gate.

A cache miss is allowed in ordinary CI. Production deployment must consume
already built images from the private OCI registry and must not run `npm`,
`flutter`, CocoaPods or Prisma downloads on the target host.
