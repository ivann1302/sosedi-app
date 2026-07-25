TEST_POSTGRES_PORT ?= 5435
TEST_REDIS_PORT ?= 6380
TEST_DATABASE_URL ?= postgresql://sosedi_test:sosedi_test@localhost:$(TEST_POSTGRES_PORT)/sosedi_test?schema=public
TEST_REDIS_URL ?= redis://localhost:$(TEST_REDIS_PORT)/15
MOBILE_LINE_COVERAGE_MIN ?= 80
TEST_COMPOSE = docker compose -f docker-compose.test.yml

.PHONY: help infra-up infra-down test-infra-up test-infra-down backend-dev backend-build backend-lint backend-lint-check backend-test backend-test-coverage backend-test-e2e backend-test-db-migrate backend-prisma-generate backend-prisma-migrate mobile-analyze mobile-test mobile-test-coverage mobile-coverage-check mobile-gen check ci hooks-install hooks-run

help:
	@printf '%s\n' \
		'Available commands:' \
		'  make infra-up                 Start PostgreSQL/PostGIS and Redis' \
		'  make infra-down               Stop infrastructure containers' \
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
		'  make mobile-analyze           Run Flutter analyzer' \
		'  make mobile-test              Run Flutter tests' \
		'  make mobile-test-coverage     Run Flutter tests with coverage gate' \
		'  make mobile-gen               Run Dart code generation' \
		'  make check                    Run fast local checks' \
		'  make ci                       Run the complete CI test suite' \
		'  make hooks-install            Install local git hooks' \
		'  make hooks-run                Run local git hooks manually'

infra-up:
	docker compose up -d

infra-down:
	docker compose down

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

mobile-gen:
	cd mobile && dart run build_runner build --delete-conflicting-outputs

check: backend-lint-check backend-test mobile-analyze mobile-test

ci: backend-lint-check backend-test-coverage backend-build backend-test-e2e mobile-analyze mobile-test-coverage

hooks-install:
	git config core.hooksPath .githooks
	chmod +x .githooks/pre-commit
	@printf '%s\n' 'Git hooks installed from .githooks'

hooks-run:
	.githooks/pre-commit
