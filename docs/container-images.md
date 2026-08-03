# Container images

Используемые PostgreSQL/PostGIS и Redis образы фиксируются одновременно
читаемым version tag и immutable registry digest:

| Назначение | Reference |
| --- | --- |
| Backend runtime/build | `node:22-bookworm-slim@sha256:6c74791e557ce11fc957704f6d4fe134a7bc8d6f5ca4403205b2966bd488f6b3` |
| PostgreSQL 15.13 + PostGIS 3.5.2 | `postgis/postgis:15-3.5@sha256:54f7933d972e107fda9b696745c21e3fcc643c4263b43f7dc43ba4bdb312fc2c` |
| Redis 7.4.9, Debian Bookworm | `redis:7.4.9-bookworm@sha256:a8f08480e1f88f2647fed492d1178c06abb0d0c1fbf02c682a61e2f483fb3954` |
| GlitchTip 6.2.2 | `glitchtip/glitchtip:6.2.2@sha256:ef28cc4b92c8c9e427b8ddd55682d6aa155129ddf1c5db5f6bbbd09155fd3b6e` |

Одинаковые references используются в локальной и test Compose-конфигурации.
Backend base-layer дополнительно фиксирует `libssl3` и `openssl`
`3.0.20-1~deb12u2`: Prisma generate/runtime не должны fallback-ить на
несуществующий OpenSSL 1.1.
Версии внутри образов проверены командами `psql --version`,
`dpkg-query -W postgresql-15-postgis-3` и `redis-server --version`.
Production должен брать те же digest из российского private registry после
закрытия следующего supply-chain пункта; замена hostname зеркала не разрешает
менять содержимое образа.

После создания repository и `docker login` образы копируются и проверяются:

```bash
OCI_REGISTRY_PREFIX=registry.example/sosedi make container-mirror
OCI_REGISTRY_PREFIX=registry.example/sosedi make production-images
```

Первый target копирует четыре нужных OCI index — Node build/runtime base,
PostGIS, Redis и GlitchTip — и для каждого сравнивает source/target digest.
Второй показывает references из обязательного `docker-compose.production.yml`
overlay. Значение prefix не содержит URL scheme, tag, digest или завершающий
slash. До успешного mirror smoke production overlay не используется.

## Backend image и rollback

`backend/Dockerfile` собирает NestJS/Prisma в multi-stage image, запускает
процесс непривилегированным `node`, содержит readiness healthcheck и не включает
`.env`, test, coverage или исходный TypeScript. Runtime filesystem read-only,
кроме ограниченного `/tmp`.

Production Compose принимает `BACKEND_IMAGE` и protected `BACKEND_ENV_FILE`.
Verifier дополнительно требует `PREVIOUS_BACKEND_IMAGE`: оба image относятся к
`OCI_REGISTRY_PREFIX`, содержат точный `@sha256:` manifest digest и различаются.
Tag или local image ID production verifier не принимает.

В защищённом env backend `TRUSTED_PROXY_IPS` должен сохранять loopback
`127.0.0.1` для container healthcheck и включать адрес/CIDR ingress proxy.
Healthcheck и локальный smoke передают `X-Forwarded-Proto: https`; внешний
периметр по-прежнему обязан завершать TLS.

```bash
OCI_REGISTRY_PREFIX=registry.example.ru/sosedi \
BACKEND_IMAGE=registry.example.ru/sosedi/backend@sha256:CURRENT \
PREVIOUS_BACKEND_IMAGE=registry.example.ru/sosedi/backend@sha256:PREVIOUS \
BACKEND_ENV_FILE=/protected/sosedi-backend.env \
POSTGRES_DB=sosedi \
POSTGRES_USER=sosedi_bootstrap \
POSTGRES_PASSWORD_FILE=/protected/postgres_password \
REDIS_PASSWORD_FILE=/protected/redis_password \
make production-images
```

`make production-boundary` независимо строит безопасный placeholder config и
проверяет, что overlay сбросил dev host ports, разделил edge/data networks и
использует mounted PostgreSQL/Redis credentials.

Перед переключением трафика оба digest по очереди проходят
`make backend-image-rollback-smoke`: readiness и публичный catalog read.
Rollback меняет только `BACKEND_IMAGE` на записанный previous digest, не
пересобирает image и не откатывает БД вслепую. После переключения повторяются
health/business smoke; если предыдущий код несовместим с миграцией, используется
forward-fix procedure из `production-operations-runbook.md`.

Локальные image IDs `sha256:...` разрешены только smoke-script для проверки
механики. Production verifier принимает исключительно registry manifest digest.

30.07.2026 актуальный backend candidate локально собран из pinned Node digest и
`package-lock.json`, затем по точному image ID запущен non-root с read-only
filesystem. Runtime smoke прошёл readiness с последней migration, публичные
categories/catalog без private location fields и bearer-защищённые metrics.
Локальный результат не является evidence российского mirror или production
deploy: там обязательны registry manifest digest и отдельные scoped credentials.

```bash
CURRENT_BACKEND_IMAGE=sha256:<candidate-image-id> \
PREVIOUS_BACKEND_IMAGE=sha256:<previous-image-id> \
BACKEND_ENV_FILE=backend/.env \
BACKEND_SMOKE_NETWORK=sosedi-app_default \
BACKEND_SMOKE_DATABASE_URL='postgresql://sosedi:sosedi@postgres:5432/sosedi?schema=public' \
BACKEND_SMOKE_REDIS_URL='redis://redis:6379' \
BACKEND_SMOKE_CORS_ALLOWED_ORIGINS='https://operator.sosedi.test' \
BACKEND_SMOKE_METRICS_TOKEN='local-smoke-token-with-at-least-32-chars' \
make backend-image-rollback-smoke
```

Обновление выполняется отдельным изменением:

1. проверить release notes и совместимость;
2. получить digest через `docker buildx imagetools inspect IMAGE:TAG`;
3. заменить tag и digest во всех Compose-файлах;
4. поднять только одноразовую test-инфраструктуру и выполнить
   `make backend-test-e2e`;
5. не пересоздавать stateful production/dev контейнер до backup и согласованного
   окна миграции.
