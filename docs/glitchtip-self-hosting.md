# GlitchTip self-hosted в РФ

Production использует GlitchTip 6.2.2 в РФ. Image зафиксирован manifest digest
`sha256:ef28cc4b92c8c9e427b8ddd55682d6aa155129ddf1c5db5f6bbbd09155fd3b6e`
и перед deploy зеркалируется в выбранный private RF OCI registry. Hosted
`app.glitchtip.com` и `sentry.io` запрещены.

Конфигурация следует официальным
[install guide](https://glitchtip.com/documentation/install/) и
[SDK contract](https://glitchtip.com/sdkdocs/all-sdks/): один all-in-one
GlitchTip service, внешние PostgreSQL 14+ и Valkey/Redis 7+, TLS reverse proxy,
явные environment/release и ограниченный sampling.

## Deployment contract

`ops/glitchtip/compose.yml`:

- публикует порт только на `127.0.0.1` за TLS proxy;
- отключает public registration, Django admin/OpenAPI, MCP, logs, uptime и cold
  storage, которые не нужны MVP;
- хранит events 90 дней, hot events 30 дней и transactions 30 дней;
- использует отдельные RF PostgreSQL/Valkey и persistent uploads volume;
- включает HSTS и собственный Prometheus endpoint GlitchTip.

Секретный env создаётся вне Git по
`ops/glitchtip/glitchtip.env.example`, имеет mode `0600` и отдельные least
privilege DB/Valkey/SMTP credentials. PostgreSQL, uploads и их backup физически
остаются в РФ.

```bash
OCI_REGISTRY_PREFIX=registry.example.ru/sosedi \
GLITCHTIP_IMAGE=registry.example.ru/sosedi/glitchtip:6.2.2@sha256:ef28cc4b92c8c9e427b8ddd55682d6aa155129ddf1c5db5f6bbbd09155fd3b6e \
GLITCHTIP_ENV_FILE=/protected/glitchtip.env \
make glitchtip-config
```

После успешного verifier: выполнить backup, обновить image digest, поднять
service, дождаться healthy, проверить migration log и только затем переключать
TLS proxy. Предыдущий digest сохраняется для application rollback; DB вслепую
не откатывается.

## Event/privacy/alert smoke

Mobile уже блокирует hosted DSN, задаёт `environment`/`release`, отключает
traces/logs/default PII/request body/screenshots и выполняет `beforeSend`
sanitizer. Unit-тест с синтетическими phone/OTP/token/address/card/URL проверяет
фактический очищенный payload.

В staging отправляется безопасное событие без ПД:

```bash
GLITCHTIP_DSN='https://public-key@errors.sosedi.ru/1' \
GLITCHTIP_SMOKE_ENVIRONMENT=staging \
GLITCHTIP_SMOKE_RELEASE='sosedi@0.1.0+1' \
make glitchtip-event-smoke
```

В UI/API найти выведенный `event_id` и подтвердить:

1. environment и release совпадают;
2. user/request/attachments отсутствуют, synthetic PII из Flutter-теста не
   попало в serialized event;
3. issue alert доставлен на RF-controlled email;
4. retention равен 90 дням, project access ограничен;
5. GlitchTip metrics scrape и backup/restore включены.

Без реального RF host, DNS/TLS, SMTP, project DSN и полученного alert пункт
production checklist остаётся BLOCKED.
