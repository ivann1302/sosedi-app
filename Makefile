TEST_POSTGRES_PORT ?= 5435
TEST_REDIS_PORT ?= 6380
TEST_DATABASE_URL ?= postgresql://sosedi_test:sosedi_test@localhost:$(TEST_POSTGRES_PORT)/sosedi_test?schema=public
TEST_REDIS_URL ?= redis://localhost:$(TEST_REDIS_PORT)/15
MOBILE_LINE_COVERAGE_MIN ?= 80
TEST_COMPOSE = docker compose -f docker-compose.test.yml

.PHONY: help infra-up infra-down container-mirror production-images production-boundary production-boundary-test release-gates release-gates-test production-smoke production-release production-rollback production-release-test backend-image-build backend-image-smoke backend-image-rollback-smoke glitchtip-config glitchtip-event-smoke environment-isolation environment-isolation-test time-sync time-sync-test alerts-verify alerts-test backup-scheduler-verify backup-scheduler-test git-backup-verify git-backup-test postgres-backup postgres-restore-drill s3-restore-sample test-infra-up test-infra-down backend-dev backend-build backend-lint backend-lint-check backend-test backend-test-coverage backend-test-e2e backend-test-db-migrate backend-prisma-generate backend-prisma-migrate backend-admin-bootstrap operator-dev operator-build public-web-dev public-web-check mobile-release-config mobile-release-config-test mobile-release-artifact-verify mobile-android-release mobile-ios-release mobile-analyze mobile-test mobile-test-coverage mobile-coverage-check mobile-ios-smoke mobile-gen security-scan check ci hooks-install hooks-run

help:
	@printf '%s\n' \
		'Available commands:' \
		'  make infra-up                 Start PostgreSQL/PostGIS and Redis' \
		'  make infra-down               Stop infrastructure containers' \
		'  make container-mirror         Mirror pinned images to OCI_REGISTRY_PREFIX' \
		'  make production-images        Validate production image references' \
		'  make production-boundary      Verify closed DB/Redis production boundary' \
		'  make release-gates            Verify release evidence and prohibitions' \
		'  make production-smoke         Run read-only smoke through production TLS' \
		'  make production-release       Deploy current digest with automatic rollback' \
		'  make production-rollback      Manually restore and smoke previous digest' \
		'  make backend-image-build      Build the production backend image' \
		'  make backend-image-smoke      Smoke one immutable backend image' \
		'  make backend-image-rollback-smoke  Smoke current then previous image' \
		'  make glitchtip-config         Validate self-hosted GlitchTip deployment' \
		'  make glitchtip-event-smoke    Send a safe release smoke event' \
		'  make environment-isolation    Verify three protected environment files' \
		'  make time-sync                Verify production host NTP and UTC' \
		'  make alerts-verify            Verify actionable Prometheus alert rules' \
		'  make backup-scheduler-verify  Verify the hardened six-hour backup timer' \
		'  make git-backup-verify        Verify independent remote contains clean HEAD' \
		'  make git-backup-test          Test independent Git backup guards' \
		'  make postgres-backup          Build and run encrypted dual-copy PostgreSQL backup' \
		'  make postgres-restore-drill   Restore an encrypted dump into a guarded isolated DB' \
		'  make s3-restore-sample        Restore and checksum one object into an isolated prefix' \
		'  make test-infra-up            Start isolated test infrastructure' \
		'  make test-infra-down          Stop isolated test infrastructure' \
		'  make backend-dev              Start NestJS in watch mode' \
		'  make backend-build            Build backend' \
		'  make backend-lint             Run backend lint with fixes' \
		'  make backend-lint-check       Run backend lint without fixes' \
		'  make backend-test             Run backend unit tests' \
		'  make backend-test-coverage    Run backend tests with coverage gate' \
		'  make backend-test-e2e         Run backend e2e with test infrastructure' \
		'  make backend-prisma-generate  Generate Prisma client' \
		'  make backend-prisma-migrate   Run Prisma dev migration' \
		'  make backend-admin-bootstrap  Create the first admin via guarded CLI' \
		'  make operator-dev             Start the React operator UI' \
		'  make operator-build           Type-check and build the operator UI' \
		'  make public-web-dev           Start the public Astro site' \
		'  make public-web-check         Check and smoke the public Astro site' \
		'  make mobile-release-config    Verify production mobile dart-defines' \
		'  make mobile-release-artifact-verify  Verify AAB/IPA against its manifest' \
		'  make mobile-android-release   Build a validated locked Android App Bundle' \
		'  make mobile-ios-release       Build a validated locked iOS archive' \
		'  make mobile-analyze           Run Flutter analyzer' \
		'  make mobile-test              Run Flutter tests' \
		'  make mobile-test-coverage     Run Flutter tests with coverage gate' \
		'  make mobile-ios-smoke         Build locked iOS release without signing' \
		'  make mobile-gen               Run Dart code generation' \
		'  make security-scan             Run offline dependency and local secret scans' \
		'  make check                    Run fast local checks' \
		'  make ci                       Run the complete CI test suite' \
		'  make hooks-install            Install local git hooks' \
		'  make hooks-run                Run local git hooks manually'

infra-up:
	docker compose up -d

infra-down:
	docker compose down

container-mirror:
	./scripts/mirror-container-images.sh

production-images:
	./scripts/verify-production-image-references.sh
	docker compose -f docker-compose.yml -f docker-compose.production.yml config --images

production-boundary:
	node ./scripts/verify-production-boundary.mjs

production-boundary-test:
	node --test ./scripts/verify-production-boundary.test.mjs

release-gates:
	node ./scripts/verify-release-gates.mjs

release-gates-test:
	node --test ./scripts/verify-release-gates.test.mjs

production-smoke:
	node ./scripts/smoke-production-release.mjs

production-release:
	node ./scripts/deploy-production-release.mjs deploy

production-rollback:
	node ./scripts/deploy-production-release.mjs rollback

production-release-test:
	node --test ./scripts/smoke-production-release.test.mjs ./scripts/deploy-production-release.test.mjs

backend-image-build:
	docker build --file backend/Dockerfile \
		--build-arg APP_RELEASE="$${BACKEND_RELEASE:-local}" \
		--tag "$${BACKEND_IMAGE_TAG:-sosedi-backend:local}" backend

backend-image-smoke:
	./scripts/smoke-backend-image.sh

backend-image-rollback-smoke:
	BACKEND_SMOKE_REQUIRE_METRICS=true BACKEND_IMAGE="$${CURRENT_BACKEND_IMAGE:?Set CURRENT_BACKEND_IMAGE}" ./scripts/smoke-backend-image.sh
	BACKEND_SMOKE_REQUIRE_METRICS=false BACKEND_IMAGE="$${PREVIOUS_BACKEND_IMAGE:?Set PREVIOUS_BACKEND_IMAGE}" ./scripts/smoke-backend-image.sh

glitchtip-config:
	./scripts/verify-glitchtip-deployment.sh
	docker compose -f ops/glitchtip/compose.yml config --images

glitchtip-event-smoke:
	node ./scripts/smoke-glitchtip-event.mjs

environment-isolation:
	node ./scripts/environment-isolation.mjs

environment-isolation-test:
	node --test ./scripts/environment-isolation.test.mjs

time-sync:
	node ./scripts/verify-time-sync.mjs

time-sync-test:
	node --test ./scripts/verify-time-sync.test.mjs

alerts-verify:
	node ./scripts/verify-alert-rules.mjs

alerts-test:
	node --test ./scripts/verify-alert-rules.test.mjs

backup-scheduler-verify:
	node ./scripts/verify-backup-scheduler.mjs

backup-scheduler-test:
	node --test ./scripts/verify-backup-scheduler.test.mjs

git-backup-verify:
	./scripts/verify-git-backup.sh

git-backup-test:
	./scripts/verify-git-backup.test.sh

postgres-backup: backend-build
	cd backend && npm run backup:postgres

postgres-restore-drill: backend-build
	cd backend && npm run restore:postgres

s3-restore-sample: backend-build
	cd backend && npm run restore:s3-sample

test-infra-up:
	TEST_POSTGRES_PORT="$(TEST_POSTGRES_PORT)" TEST_REDIS_PORT="$(TEST_REDIS_PORT)" $(TEST_COMPOSE) up -d --wait --wait-timeout 90

test-infra-down:
	TEST_POSTGRES_PORT="$(TEST_POSTGRES_PORT)" TEST_REDIS_PORT="$(TEST_REDIS_PORT)" $(TEST_COMPOSE) down --remove-orphans

backend-dev:
	cd backend && npm run start:dev

backend-build:
	cd backend && npm run build

backend-lint:
	cd backend && npm run lint

backend-lint-check:
	cd backend && npx eslint "{src,apps,libs,test}/**/*.ts"

backend-test:
	cd backend && npm test

backend-test-coverage:
	cd backend && npm run test:cov -- --runInBand

backend-test-db-migrate:
	cd backend && DATABASE_URL="$(TEST_DATABASE_URL)" npx prisma migrate deploy

backend-test-e2e: test-infra-up
	$(MAKE) --no-print-directory backend-test-db-migrate
	cd backend && NODE_ENV=test TEST_DATABASE_URL="$(TEST_DATABASE_URL)" TEST_REDIS_URL="$(TEST_REDIS_URL)" npm run test:e2e -- --runInBand

backend-prisma-generate:
	cd backend && npx prisma generate

backend-prisma-migrate:
	cd backend && npx prisma migrate dev

backend-admin-bootstrap:
	cd backend && npm run admin:bootstrap

operator-dev:
	cd operator && npm run dev

operator-build:
	cd operator && npm run build

public-web-dev:
	cd public-web && npm run dev

public-web-check:
	cd public-web && npm run check

mobile-release-config:
	node ./scripts/verify-mobile-release-config.mjs

mobile-release-config-test:
	node --test ./scripts/verify-mobile-release-config.test.mjs ./scripts/build-mobile-release.test.mjs ./scripts/verify-mobile-release-artifact.test.mjs

mobile-release-artifact-verify:
	node ./scripts/verify-mobile-release-artifact.mjs

mobile-android-release:
	node ./scripts/build-mobile-release.mjs appbundle

mobile-ios-release:
	node ./scripts/build-mobile-release.mjs ipa

mobile-analyze:
	cd mobile && flutter analyze

mobile-test:
	cd mobile && flutter test

mobile-test-coverage:
	cd mobile && flutter test --coverage
	$(MAKE) --no-print-directory mobile-coverage-check

mobile-coverage-check:
	@test -f mobile/coverage/lcov.info || (printf '%s\n' 'Missing mobile/coverage/lcov.info' && exit 1)
	@awk -F: -v minimum="$(MOBILE_LINE_COVERAGE_MIN)" '\
		/^SF:/ { \
			source = substr($$0, 4); \
			included = source !~ /\.g\.dart$$/ && source !~ /\.freezed\.dart$$/; \
			next; \
		} \
		included && /^LF:/ { total += $$2 } \
		included && /^LH:/ { covered += $$2 } \
		/^end_of_record$$/ { included = 0 } \
		END { \
			if (total == 0) { \
				print "Flutter coverage report contains no lines"; \
				exit 1; \
			} \
			percentage = covered * 100 / total; \
			printf "Flutter line coverage: %.2f%% (minimum %.2f%%)\n", percentage, minimum; \
			if (percentage + 0.000001 < minimum) exit 1; \
		}' mobile/coverage/lcov.info

mobile-ios-smoke:
	cd mobile && flutter pub get --enforce-lockfile
	cd mobile/ios && pod install --deployment
	cd mobile && flutter build ios --release --no-codesign --no-pub

mobile-gen:
	cd mobile && dart run build_runner build --delete-conflicting-outputs

security-scan:
	@command -v osv-scanner >/dev/null || (printf '%s\n' 'Missing osv-scanner' && exit 1)
	@command -v gitleaks >/dev/null || (printf '%s\n' 'Missing gitleaks' && exit 1)
	osv-scanner scan source --recursive --offline --offline-vulnerabilities --no-resolve --config=backend/osv-scanner.toml .
	gitleaks git --no-banner --redact --exit-code=1 .
	gitleaks dir --no-banner --redact --exit-code=1 .

check: environment-isolation-test time-sync-test alerts-verify alerts-test backup-scheduler-verify backup-scheduler-test git-backup-test production-boundary-test release-gates-test production-release-test mobile-release-config-test backend-lint-check backend-test operator-build public-web-check mobile-analyze mobile-test

ci: environment-isolation-test time-sync-test alerts-verify alerts-test backup-scheduler-verify backup-scheduler-test git-backup-test production-boundary production-boundary-test release-gates-test production-release-test mobile-release-config-test backend-lint-check backend-test-coverage backend-build backend-test-e2e operator-build public-web-check mobile-analyze mobile-test-coverage

hooks-install:
	git config core.hooksPath .githooks
	chmod +x .githooks/pre-commit
	@printf '%s\n' 'Git hooks installed from .githooks'

hooks-run:
	.githooks/pre-commit
