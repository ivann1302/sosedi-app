.PHONY: help infra-up infra-down backend-dev backend-build backend-lint backend-test backend-test-e2e backend-prisma-generate backend-prisma-migrate mobile-analyze mobile-test mobile-gen check ci backend-lint-check hooks-install hooks-run

help:
	@printf '%s\n' \
		'Available commands:' \
		'  make infra-up                 Start PostgreSQL/PostGIS and Redis' \
		'  make infra-down               Stop infrastructure containers' \
		'  make backend-dev              Start NestJS in watch mode' \
		'  make backend-build            Build backend' \
		'  make backend-lint             Run backend lint with fixes' \
		'  make backend-lint-check       Run backend lint without fixes' \
		'  make backend-test             Run backend unit tests' \
		'  make backend-test-e2e         Run backend e2e tests' \
		'  make backend-prisma-generate  Generate Prisma client' \
		'  make backend-prisma-migrate   Run Prisma dev migration' \
		'  make mobile-analyze           Run Flutter analyzer' \
		'  make mobile-test              Run Flutter tests' \
		'  make mobile-gen               Run Dart code generation' \
		'  make check                    Run common checks' \
		'  make ci                       Run CI checks' \
		'  make hooks-install            Install local git hooks' \
		'  make hooks-run                Run local git hooks manually'

infra-up:
	docker-compose up -d

infra-down:
	docker-compose down

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

backend-test-e2e:
	cd backend && npm run test:e2e

backend-prisma-generate:
	cd backend && npx prisma generate

backend-prisma-migrate:
	cd backend && npx prisma migrate dev

mobile-analyze:
	cd mobile && flutter analyze

mobile-test:
	cd mobile && flutter test

mobile-gen:
	cd mobile && dart run build_runner build --delete-conflicting-outputs

check: backend-lint backend-test mobile-analyze mobile-test

ci: backend-lint-check backend-test backend-build mobile-analyze mobile-test

hooks-install:
	git config core.hooksPath .githooks
	chmod +x .githooks/pre-commit
	@printf '%s\n' 'Git hooks installed from .githooks'

hooks-run:
	.githooks/pre-commit
