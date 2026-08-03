# Recovery objectives и restore drill

Статус: targets приняты для MVP; production drill PostgreSQL + S3 остаётся
release blocker до назначения реальных RF providers.

| Система | RPO | RTO | Проверка |
| --- | --- | --- | --- |
| PostgreSQL/PostGIS | 6 часов | 4 часа | Encrypted dual-provider dump каждые 6 часов; isolated restore + migration/readiness |
| S3 public/private objects | 6 часов | 8 часов | Independent RF copy, checksum inventory и restore referenced object sample |
| Backend/operator/public config | Последний approved release | 2 часа | Immutable digest/config archive rollback |
| Redis/OTP/refresh/BullMQ | Durable business records не зависят от Redis; активные sessions/jobs могут быть потеряны | 1 час | Rebuild Redis, revoke sessions, replay durable outbox |
| GlitchTip | 24 часа | 8 часов | Self-hosted DB/object restore; потеря observability не открывает traffic gate |

RPO/RTO — максимальные цели, не обещание SLA. Любое превышение создаёт P0/P1
incident по impact. Изменение targets требует Product owner и operations review.

## Quarterly isolated drill

1. Выбрать secondary PostgreSQL backup и связанные S3 objects одной UTC cutoff.
2. Создать новые isolated network/DB/buckets без public access. Имена restore DB
   начинаются `sosedi_restore_`; production credentials не используются.
3. Запустить guarded `make postgres-restore-drill`, затем application readiness
   против restored DB/isolated Redis.
4. Восстановить по manifest один public item image, private booking evidence и
   deletion marker; для каждого bounded sample выполнить
   `make s3-restore-sample`, сверить size/SHA-256/version metadata и
   authorization.
5. Применить deletion/tombstone jobs до открытия любого test traffic. Убедиться,
   что удалённый object/PII не ожил.
6. Выполнить read-only business smoke: user/item/booking snapshot relation,
   private evidence participant guard и redacted public response.
7. Уничтожить только явно названные isolated resources по provider procedure.
   Записать backup IDs, start/end UTC, achieved RPO/RTO, checks, deviations и
   follow-up owner без ПД/credentials.

## Текущее evidence

- AES-256-GCM round-trip/tamper tests и isolated target guard автоматизированы.
- S3 sample CLI до любого target write сверяет ожидаемый SHA-256 и явное
  подтверждение `bucket/sosedi-restore-sample/<drill-id>`, затем перечитывает
  восстановленный object; source key в evidence представлен только SHA-256.
- 29.07.2026 выполнен controlled local migration/restore drill: актуальный
  PostgreSQL 15 custom dump зашифрован и расшифрован с совпавшим SHA-256,
  восстановлен в `sosedi_restore_drill_20260729_v2`, затем на синтетической
  связке lender/item/booking/act/evidence смоделировано состояние до migration
  `20260729001600_rename_notification_outbox_constraints` и штатно выполнен
  `prisma migrate deploy`. Проверены новая constraint name, отсутствие orphan
  relations, booking terms/evidence reference, backend readiness и redacted
  public item response. `npm run start:prod` также исправлен на фактический
  build entrypoint `dist/src/main.js`.
- 29.07.2026 повторён negative production-like drill на текущей схеме:
  PostgreSQL 15 custom dump с synthetic lender/item/booking/act/evidence
  зашифрован AES-256-GCM, guarded restore выполнен в
  `sosedi_restore_negative_20260729`. Smoke подтвердил `2/1/1/1/1`
  user/item/booking/act/evidence, `0` Payment/orphan relations и сохранённый
  `PAY_ON_HANDOVER` snapshot. Current и previous exact local image IDs прошли
  readiness/categories/catalog/privacy smoke на restored DB; automatic rollback
  fail-path tests — `6/6`. Нестабильный старый rollback artifact с Prisma/OpenSSL
  warning исключён, backend image теперь содержит pinned OpenSSL 3.
- Этот local drill подтверждает migration/forward-fix procedure и совместимость
  схемы с representative data. Он не подтверждает production RPO/RTO, объём
  production dataset или восстановление реальных S3 objects.
- Реальный PostgreSQL restore и S3 object restore из двух RF providers ещё не
  выполнены: provider references/credentials отсутствуют.
- Поэтому production restore-drill и automatic PostgreSQL backup раздела 17.3
  остаются открытыми; локальный negative drill раздела 18 ими не подменяется.
