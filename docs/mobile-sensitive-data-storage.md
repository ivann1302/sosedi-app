# Mobile sensitive data storage

## Persistent storage allowlist

- `flutter_secure_storage`: access/refresh tokens and one authenticated user's
  unfinished listing draft containing only non-location fields. The draft is
  removed after submit or logout.
- `shared_preferences`: installation UUID, onboarding completion и локальный
  analytics consent (`unknown/granted/denied`) без user ID.

Exact addresses, booking handover/contact, evidence, KYC and payment payloads
must not be written to local files, preferences, databases, logs or analytics.
Listing photos, file paths, exact address, latitude/longitude and legal
acceptance checkboxes are never included in the persisted listing draft.

## In-memory lifetime

- Private profile, session and booking providers are auto-disposed after their
  screen loses its last listener.
- Every transition out of authenticated state invalidates all private providers,
  pending notification navigation and mutation controllers.
- The create-listing screen drops selected `XFile` references and its controller
  when the route is disposed.
- Mutation completion invalidates affected entity providers; terminal/cancel
  commands must do the same when their mobile actions are added.

This is a code-level allowlist. Any new persistence dependency or cache requires
an explicit review against this document before storing a new key.
