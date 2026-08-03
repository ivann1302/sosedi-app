# Monitoring alert runbooks

Для всех alerts сначала подтвердить target/environment, UTC начала и фактическое
значение сигнала. В incident record не копировать tokens, connection strings,
provider payload, пользовательские ID или ПД. `critical` получает Product owner
и on-call operator; `warning` — on-call operator с escalation владельцу, если
порог сохраняется или затрагивает безопасность/деньги.

## Metrics and API

Проверить liveness/readiness, последний deploy digest, 5xx route/status и
latency по агрегированным labels. При провале readiness убрать instance из
трафика. При release-регрессии применить rollback runbook; иначе ограничить
конкретный failing entry point и сохранить безопасные логи.

## Database and disk

Проверить connections, long-running queries и место конкретного filesystem.
Остановить несущественные jobs, если они усиливают нагрузку. Не удалять WAL,
backup или data вручную. При диске ниже 15% расширить volume по provider
процедуре; при DB saturation ограничить новые writes и проверить pool/leak.

## Redis

Проверить used/max memory, eviction policy, OTP/refresh и queue latency. Не
выполнять широкую очистку Redis: сначала определить affected keyspace и durable
source. Настроить безопасный maxmemory или расширить ресурс, затем проверить
auth и queues.

## Queues and outbox

Зафиксировать queue, failed/stalled count, outbox/push oldest age и число
`PENDING/PROCESSING/RETRY`. Остановить только affected consumer при poison job,
проверить provider status, lease, idempotency и retry count. После исправления
повторно обработать одну безопасную запись и подтвердить отсутствие дубликата
inbox/side effect.

## Provider operation

Определить operation без раскрытия payload. Проверить provider status, mode,
quota и credential expiry. Остановить retry storm; не переключать test/live и
не включать gated payment/KYC функцию. После восстановления выполнить один
staged safe smoke.
Для `otp_global_limit` проверить распределённый abuse, значение Redis cap и
остаток бюджета в кабинете SMS; увеличивать cap только с подтверждением Product
owner, не добавляя phone/IP/user в metrics или incident record.

## Backup

Остановить release и destructive migrations. Проверить scheduler result,
возраст последней подтверждённой dual-copy backup и обе RF copies. Backup
считается восстановленным только после изолированного restore drill по
recovery runbook. Если series отсутствует, проверить mount/write permission
`BACKUP_METRICS_FILE` и node-exporter textfile collector; не создавать timestamp
вручную без успешных двух `HEAD`-проверок и retention.
Для `SosediPostgresBackupSchedulerFailed` проверить
`systemctl status sosedi-postgres-backup.service` и scoped journal unit, не
очищая failed state до фиксации причины. После исправления запустить один
controlled service, проверить две RF-копии, freshness metric и только затем
сбросить incident.

## TLS and domain

Проверить authoritative DNS, registrar status, certificate chain и expiry с
двух независимых сетевых точек. Product owner продлевает domain/certificate
через MFA account. Не отключать TLS verification. После исправления проверить
API, public/operator URLs и callback endpoints.

## Provider expiry

Сверить только reference и expiry/rotation due date в закрытом access register.
Product owner выпускает новый credential, scoped identity выполняет staged
smoke, затем старый credential отзывается. Textfile metric обновляется
атомарно; plaintext credential в metric, label и incident record запрещён.
