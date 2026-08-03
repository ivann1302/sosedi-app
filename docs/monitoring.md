# Production monitoring

Для MVP используется один Prometheus-compatible endpoint backend и внешние
infra/scheduler exporters. Prometheus, Alertmanager и dashboard размещаются в РФ
в закрытой сети. Метрики не содержат phone, user/item/booking ID, адрес, URL,
provider payload или другие high-cardinality/персональные labels.

## Backend endpoint

`GET /api/v1/internal/metrics` требует
`Authorization: Bearer <METRICS_TOKEN>`. В production token обязателен, содержит
минимум 32 символа, хранится в secret manager и отличается от JWT/provider
secrets. Scrape credential передаётся Prometheus через `credentials_file`, а не
коммитится в конфигурацию.

Endpoint отдаёт:

- HTTP request count по method/status и общий latency histogram;
- PostgreSQL connections/max connections и размер БД;
- Redis used/max memory;
- BullMQ waiting/active/failed/delayed и stalled counter;
- pending/oldest age notification outbox и состояние/возраст push delivery;
- outcomes SMS, исчерпания global OTP cap и обработки upload без пользовательских
  идентификаторов;
- заранее стабильные series для payment/webhook/payout/refund/receipt/backup.

Readiness остаётся отдельным traffic gate. Metrics endpoint не заменяет
`/health/ready` и при ошибке DB/Redis должен дать scrape error, чтобы сработал
`SosediMetricsMissing`.

Пример private-network scrape:

```yaml
scrape_configs:
  - job_name: sosedi-backend
    scheme: https
    metrics_path: /api/v1/internal/metrics
    authorization:
      type: Bearer
      credentials_file: /run/secrets/sosedi_metrics_token
    static_configs:
      - targets: [api.internal.sosedi.ru]
```

## Alerts и ownership

Правила находятся в `ops/monitoring/prometheus-alerts.yml`.

| Signal | MVP alert | Source |
| --- | --- | --- |
| API 5xx / latency | 5xx > 5% 10m; p95 > 1s 10m | backend endpoint |
| DB connections | > 80% 10m | backend endpoint |
| Production disk | free < 15% 15m | node exporter on backend/DB/monitoring hosts |
| Redis memory | maxmemory missing or used > 80% | backend endpoint |
| BullMQ / outbox / push | failed/stalled; outbox > 60s; push > 300s | backend endpoint |
| SMS / OTP cap / upload | any failure в 10m; cap имеет отдельную series | instrumented backend operations |
| webhook/payout/refund/receipt | any failure in 10m | series reserved; wire at feature implementation |
| PostgreSQL backup | metric absent, no success for 7h or scheduler non-zero | node-exporter textfile + scheduler |
| TLS / DNS | certificate < 14d; DNS probe fails 5m | RF Blackbox Exporter |
| Domain registration | expiry < 30d | protected access-register exporter |
| Provider credential | expiry/rotation due < 30d | protected access-register exporter |

Product owner receives critical alerts; on-call operator receives warning and
critical alerts. Provider spend/quota alerts stay enabled in SMS/payment
provider cabinets in addition to application failures.
Каждое правило содержит `owner`, явный `threshold` и ссылку на
[`monitoring-alert-runbooks.md`](monitoring-alert-runbooks.md); CI проверяет этот
контракт через `make alerts-verify`.

`payment_checkout`, `payment_webhook`, `payout`, `refund` and `receipt` are not
production-enabled before their legal/provider gates. Their metric names and
alerts are fixed now, but each integration must call `recordOperation` at its
actual boundary and pass a staged failure smoke before its checklist item can
close.

Backup job runs outside the API identity. После проверки обеих encrypted RF
copies и успешного retention он атомарно публикует через node-exporter textfile
`sosedi_backup_last_success_timestamp_seconds`; absent series и возраст более
7 часов сами являются alert. На backup host node_exporter systemd collector
ограничен `sosedi-postgres-backup.service`; его
`node_systemd_unit_state{state="failed"}` сигнализирует non-zero scheduler
result. Не выдавать backup S3 credentials runtime backend только ради metrics.

Blackbox Exporter в закрытом RF monitoring environment проверяет HTTPS/TLS и
authoritative DNS. Отдельный scheduler читает только expiry metadata из
закрытого access register и атомарно публикует через node-exporter textfile
collector:

```text
sosedi_domain_expiry_timestamp_seconds{domain="public"} 1800000000
sosedi_provider_credential_expiry_timestamp_seconds{provider="smsru"} 1800000000
```

Labels — только малый allowlist логических имён, без account IDs, URL, email,
credential values или иных секретов. Для credential без provider expiry
публикуется утверждённая дата обязательной rotation. Отсутствие обоих inventory
signals больше часа само является alert.

## Deployment acceptance

1. Without bearer token the metrics endpoint returns `401`; with the secret it
   returns Prometheus text over TLS.
2. Trigger one controlled staging `5xx`, BullMQ failure and SMS/provider fake
   failure; confirm delivery and recovery of alerts.
3. Verify DB-host disk exporter labels match `job="postgres-node"`.
4. Break the backup job in staging and confirm both immediate scheduler alert
   and 7-hour freshness rule with an overridden short test threshold.
5. Проверить staged TLS/DNS failure и короткие synthetic domain/provider expiry;
   подтвердить delivery, owner routing и recovery notification.
6. Record Prometheus/Alertmanager URLs, rule revision and alert delivery
   evidence in the release checklist without including credentials.
