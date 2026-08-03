# Production release smoke и rollback gate

Release target меняет только backend image на уже собранный exact manifest
digest. Migration выполняется отдельной short-lived identity до target и только
по expand/compatible plan. Release script не изменяет schema, secrets, DB/Redis
containers или provider configuration.

## Обязательный smoke

`make production-smoke` обращается только к credential-free HTTPS origin и
проверяет:

1. `/api/v1/health/live`;
2. `/api/v1/health/ready`, включая DB, migrations, Redis и clock;
3. read-only список categories;
4. read-only public Items catalog.

Smoke не запрашивает OTP, не создаёт пользователя/бронь, не отправляет SMS и не
передаёт access token. Readiness ждёт до 90 секунд; любой HTTP/contract failure
считается провалом release.

## Deploy с automatic rollback

Protected release environment передаёт:

- `RELEASE_CHANGE_ID` без ПД/секретов;
- `RELEASE_COMMIT_SHA` точного CI commit и `RELEASE_GATE_FILE` из protected
  release environment;
- `PRODUCTION_BASE_URL`;
- current `BACKEND_IMAGE` и `PREVIOUS_BACKEND_IMAGE` exact digests;
- protected backend/PostgreSQL/Redis secret file references и Compose values.

```bash
make production-release
```

Порядок: release evidence verifier → immutable-reference verifier →
network/credential boundary verifier → `docker compose up --no-deps --wait
backend` current digest → HTTPS smoke. При ошибке deploy или smoke script сразу
разворачивает previous digest и повторяет тот же smoke. Даже при успешном
восстановлении команда завершится non-zero, чтобы CI/change не отметил release
успешным.

## Release prohibition evidence

Protected JSON создаётся из
`ops/release/release-gate.example.json`; пример намеренно имеет `blocked` и не
может пройти verifier. Реальный файл не коммитится и содержит только references,
statuses и timestamps — без finding details, ПД или secret values.

`make release-gates` требует:

- successful CI для точного commit и backend digest;
- ноль открытых P0 security/privacy findings с проверкой не старше 24 часов;
- PostgreSQL + S3 restore drill не старше 90 дней в принятых RPO/RTO; S3
  evidence содержит checksum-bound sample result (`sha256`, hashed source key,
  size и isolated target reference), одного boolean недостаточно;
- accepted marketplace legal/safety gate и версии offer/rules/privacy/
  prohibited-items;
- точное совпадение `MARKETPLACE_OFFER_VERSION` с approved offer и
  `MARKETPLACE_CANCELLATION_POLICY_VERSION` с approved rental rules; пустые,
  draft и несовпадающие runtime-версии блокируют deploy;
- mobile artifact собран с этими же двумя версиями/URL и точной versioned
  privacy парой `MARKETPLACE_PRIVACY_VERSION`/`MARKETPLACE_PRIVACY_URL`; без
  полного набора mobile скрывает документы, а booking submit остаётся
  fail-closed без offer/rental-rules;
- свежий smoke публичных HTTPS URL этих версий, support и account deletion;
- свежий smoke записи versioned acceptance в Booking;
- MFA/operator/audit smoke не старше 24 часов;
- accepted payment provider/legal gate только если provider mode `live`;
- accepted ADR/legal reference только если KYC включён;
- Product owner и legal approval references.

Несовпадение release ID, commit, image или provider mode блокирует deploy до
любого обращения к Docker/provider control plane.

Перед Flutter release build те же публичные значения передаются environment и
проверяются `make mobile-release-config`:

```bash
APP_ENVIRONMENT=production \
APP_RELEASE=sosedi@1.0.0+42 \
RELEASE_COMMIT_SHA=FULL_GIT_COMMIT_SHA \
API_BASE_URL=https://api.sosedi.ru/api/v1 \
MARKETPLACE_OFFER_VERSION=APPROVED_OFFER \
MARKETPLACE_OFFER_URL=https://PUBLIC/documents/offer/APPROVED_OFFER/ \
MARKETPLACE_CANCELLATION_POLICY_VERSION=APPROVED_RULES \
MARKETPLACE_RENTAL_RULES_URL=https://PUBLIC/documents/rental-rules/APPROVED_RULES/ \
MARKETPLACE_PRIVACY_VERSION=APPROVED_PRIVACY \
MARKETPLACE_PRIVACY_URL=https://PUBLIC/documents/privacy-consent/APPROVED_PRIVACY/ \
make mobile-release-config
```

`make mobile-release-config` — быстрый preflight без сборки. Для артефакта
используется `make mobile-android-release` или `make mobile-ios-release` с теми
же environment values: wrapper сначала выполняет verifier, проверяет
зафиксированные Dart/CocoaPods lock-файлы и сам передаёт точный набор
`--dart-define`. localhost/http, draft, credential-bearing URL, неверный
`/api/v1` path, IP/reserved host и URL без точного version segment отклоняются
до запуска Flutter. После успеха рядом с AAB/IPA создаётся
`sosedi-release-manifest.json` с SHA-256 артефакта, полным commit SHA и тем же
public config; manifest сохраняется как protected release evidence и не содержит
credentials. Перед store upload команда
`MOBILE_RELEASE_MANIFEST_PATH=... make mobile-release-artifact-verify` с тем же
environment повторно сверяет реальные байты AAB/IPA, commit и config; symlink и
path traversal отклоняются. До Flutter wrapper также требует точное совпадение
`RELEASE_COMMIT_SHA` с `git HEAD` и полностью чистый tracked/untracked worktree.
Формат `APP_RELEASE=sosedi@MAJOR.MINOR.PATCH+BUILD` обязателен: из него wrapper
передаёт Flutter точные `--build-name` и `--build-number`.

Если rollback smoke тоже не проходит, это P0: остановить rollout, убрать
instance из traffic и выполнять incident/forward-fix procedure. Не делать
blind down migration.

## Manual rollback

```bash
make production-rollback
```

Команда разворачивает `PREVIOUS_BACKEND_IMAGE` и считается успешной только после
обязательного HTTPS smoke. Change record хранит current/previous digest, UTC,
operator, migration compatibility и оба результата; secret values туда не
попадают.

## Provider adaptation

Compose target является исполняемым MVP contract. Если выбранный RF compute
использует свой deploy API, adapter обязан сохранить тот же порядок и exit
semantics: exact digest, bounded readiness, четыре smoke checks, automatic
previous digest restore и повторный smoke. До staged failure drill provider
adapter не считается готовым.
