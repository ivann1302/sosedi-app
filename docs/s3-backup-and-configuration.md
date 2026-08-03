# S3 backup, versioning и configuration recovery

Статус: policy зафиксирована; реальные provider/bucket references и restore
evidence обязательны до production release. Документ не разрешает LOCAL_KYC и
не содержит credentials.

## Bucket и prefix policy

MVP использует один основной S3-compatible provider в РФ и два логических
buckets:

| Boundary | Prefixes/data | Versioning и lifecycle |
| --- | --- | --- |
| Public | `items/`, `avatars/`; только обработанные изображения | Versioning enabled; current object живёт по product retention, noncurrent versions и delete markers очищаются после 35 дней |
| Private | `quarantine/item-photos/`, `quarantine/avatars/`, `quarantine/booking-evidence/`, `quarantine/support-attachments/` | Versioning enabled; expired/unconfirmed noncurrent versions не дольше 24 часов, rejected decode — не дольше 7 дней |
| Private | Confirmed handover/evidence и support attachment objects | Нет public ACL; current object по `data-retention-and-export.md`, noncurrent versions после удаления — 35 дней |
| Private, disabled | KYC document prefix | Prefix и write permission отсутствуют до отдельного `ACCEPTED LOCAL_KYC` ADR |

Bucket-level versioning не отменяет product deletion: lifecycle удаляет
noncurrent versions по prefix, а restore перед открытием трафика повторно
применяет deletion/tombstone register. Legal hold разрешён только для конкретного
case/object set с owner и review date; общий бессрочный hold запрещён.

## Независимая RF-копия

- Primary bucket и backup destination находятся у разных российских providers,
  в разных accounts и failure domains.
- Backup identity имеет read current/version metadata только на allowlisted
  prefixes primary и write/list/delete только на backup destination.
- Каждые 6 часов копируются новые/изменённые objects вместе с version ID,
  content type, size, checksum, source key и created timestamp в зашифрованный
  backup namespace. Private objects не становятся public.
- Ежедневный inventory сверяет count, total bytes и checksum sample по каждому
  prefix; расхождение или отсутствие успешного цикла более 7 часов вызывает
  alert.
- Backup retention — 35 дней после product deletion. Current objects с более
  длинным business/legal сроком остаются current и продолжают копироваться.
- Primary delete не удаляет secondary copy раньше retention; secondary identity
  не доступна application runtime.

Конкретный provider replication API не является обязательным: для MVP допустим
один bounded batch copier. Три storage adapters в application code не
добавляются.

## Configuration и signing metadata

После каждого изменения экспортируются только versioned configuration и
metadata:

- bucket names/references, region, endpoint, versioning, lifecycle, CORS,
  public-access block, encryption и IAM policy documents;
- DNS/TLS resource references, reverse-proxy config, OCI digests и deployment
  manifest;
- provider mode/merchant/app identifiers, webhook URL/event allowlist и key
  version/expiry без secret value;
- App Store/Google Play/RuStore app ID, bundle/package name, certificate/profile
  ID и expiry, signing key fingerprint и backup verification date;
- GlitchTip project/retention/alert configuration и redaction revision.

Export получает UTC timestamp, source revision и SHA-256 manifest, шифруется
ключом из secret manager и хранится в primary operations archive плюс
зашифрованной offline copy owner. Private signing keys и recovery codes не
входят в этот export: они хранятся отдельной encrypted offline backup по
`store-readiness.md` и `production-secrets-runbook.md`.

## Restore order

1. Создать изолированные empty buckets без public access и восстановить
   versioning/lifecycle/IAM configuration.
2. Восстановить PostgreSQL в изолированную DB, затем только referenced current
   S3 objects и разрешённые versions.
3. Для bounded sample не больше 20 МБ запустить `make s3-restore-sample`.
   Source и target используют отдельные scoped credentials; обязательны HTTPS
   endpoints, expected SHA-256, exact source key/version и target prefix вида
   `sosedi-restore-sample/<drill-id>`. `S3_RESTORE_CONFIRM_TARGET` должен точно
   равняться `<target-bucket>/<target-prefix>`, а target bucket обязан отличаться
   от source bucket. Source/target access key IDs также обязаны различаться; CLI
   отклоняет общую identity и неизолированную цель до S3 I/O, до загрузки требует
   `ContentLength` в пределах 20 МБ, пишет AES256 object, повторно читает его и
   не выводит source key/credentials.
4. Проверить manifest/checksum, отсутствие unexpected public ACL и object
   authorization через application service identity.
5. Применить deletion/tombstone и expired retention jobs; только затем
   разрешить readiness/traffic.
6. Sample: public item image, private booking evidence и deleted object,
   который не должен ожить. KYC sample запрещён, пока LOCAL_KYC не принят.

## Release evidence

Закрытый operational record обязан содержать primary/secondary provider
references, lifecycle/versioning screenshots or API export hashes, дату
последнего successful copy, checksum reconciliation, restore sample и owner.
До появления этого evidence inventory сохраняет S3 как release blocker.
