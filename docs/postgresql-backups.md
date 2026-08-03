# PostgreSQL backups

Статус: repository job и hardened systemd schedule готовы; установка schedule и
две реальные RF storage destination должны быть подтверждены provider smoke до
закрытия checklist.

## Контракт job

`make postgres-backup`:

1. запускает `pg_dump` той же major-версии 15 в custom format без owner/ACL;
2. шифрует dump потоково AES-256-GCM уникальным nonce и ключом из secret manager;
3. считает SHA-256 зашифрованного файла;
4. загружает один object в primary и independent secondary S3-compatible
   provider с разными endpoint host;
5. через `HEAD` сверяет размер и SHA-256 metadata обеих сохранённых копий;
6. только после двух успешных upload и проверок удаляет objects старше 35 дней в обеих
   destination;
7. только после успешного retention атомарно обновляет
   `BACKUP_METRICS_FILE=/.../sosedi_backup.prom` для node-exporter textfile
   collector;
8. удаляет local temporary dump даже при ошибке и возвращает non-zero для alert.

Plaintext dump и encryption key не попадают в object metadata или logs.
Credential values передаются только runtime identity/secret manager. Job
запускается в закрытой сети рядом с DB; `DATABASE_URL` не передаётся аргументом
`pg_dump`, password попадает только в environment дочернего процесса.

## Required secret metadata

Значения не хранятся в Git:

- `DATABASE_URL`, `BACKUP_ENCRYPTION_KEY_BASE64`;
- `BACKUP_PRIMARY_S3_*` и `BACKUP_SECONDARY_S3_*`;
- owner, provider reference, bucket/prefix scope, created/rotated/expires и
  revoke procedure для каждой identity.

`BACKUP_METRICS_FILE` не является secret, но обязателен и должен быть абсолютным
путём с basename `sosedi_backup.prom` в существующем textfile collector
directory. Job пишет временный файл в той же директории и выполняет atomic
rename; частичный upload, failed HEAD или retention не обновляют timestamp.

Primary и secondary обязаны находиться у независимых российских providers.
Разные buckets одного endpoint не считаются независимой копией. Identity имеет
только `put/list/delete` на backup bucket/prefix; application runtime не читает
backup.

## Scheduler

Repository units
`ops/systemd/sosedi-postgres-backup.{service,timer}` запускают job в
00:00/06:00/12:00/18:00 UTC. `oneshot` service не допускает overlap, имеет
timeout 60 минут, работает как отдельный `sosedi-backup` с `UMask=0077`,
protected filesystem и единственным writable-путём node-exporter textfile
collector. `Persistent=true` догоняет пропущенный запуск после перезагрузки.
Protected `/etc/sosedi/backup.env` не входит в Git.

Перед установкой выполнить `make backup-scheduler-verify`. На production host
создать непривилегированного system user/group, установить units с mode `0644`,
а env с owner `root`, mode `0600`; затем выполнить `systemctl daemon-reload`,
`systemctl enable --now sosedi-postgres-backup.timer` и проверить
`systemctl list-timers sosedi-postgres-backup.timer`. Первый controlled запуск
service обязан успешно записать обе копии и freshness metric. Node-exporter/
systemd collector должен включать только `sosedi-postgres-backup.service`;
monitoring поднимает alert на failed unit, отсутствие успешного object более
7 часов или retention failure.

Job runtime обязан содержать Node production dependencies и PostgreSQL 15
`pg_dump`; артефакт фиксируется digest и зеркалируется в private OCI registry РФ.

## Production smoke, который ещё обязателен

1. Назначить primary/secondary provider references в закрытом inventory.
2. Запустить job с production-like DB и убедиться, что object/digest metadata
   появились у обоих providers.
3. С отдельной restore identity скачать secondary copy, проверить GCM tag и
   выполнить `pg_restore --list` в изолированной среде.
4. Искусственно создать expired test object и подтвердить удаление только
   backup-prefix objects старше 35 дней.
5. Отозвать primary credential и убедиться, что job падает и alert срабатывает,
   не выдавая ложный success при одной копии.

`make postgres-restore-drill` расшифровывает выбранный object локально, сначала
выполняет `pg_restore --list`, проверяет отсутствие application tables (кроме
служебной `public.spatial_ref_sys` PostGIS), затем восстанавливает без `--clean`
только в заранее созданную empty DB с именем `sosedi_restore_*`. Защита требует точного
`RESTORE_CONFIRM_TARGET=host:port/database` и после restore сверяет последнюю
Prisma migration. Restore credential и encryption key передаются только через
закрытое runtime environment; исходная production DB этим job не изменяется.

До выполнения этих пяти шагов пункт «автоматические PostgreSQL backups» остаётся
открытым.
