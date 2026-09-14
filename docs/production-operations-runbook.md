# Production inventory и operations runbook

Статус: обязательный реестр и процедура для первого production release. Здесь
нет адресов инфраструктуры, credential values, персональных телефонов или
break-glass данных.

## Роли и владение доступом

До появления команды один человек может совмещать роли, но использует разные
human и service identities:

| Роль | Ответственность |
| --- | --- |
| Product owner | Принимает release/risk-решение и владеет provider billing/account recovery |
| Release operator | Выполняет deploy, smoke и rollback через MFA human account |
| Incident commander | Координирует containment, recovery, коммуникацию и закрытие incident |
| Privacy/legal owner | Решает breach notification, legal hold и допустимость восстановления данных |

Human owner для всех production accounts — Product owner. Технический
исполнитель — Release operator. Runtime, migration, CI и deploy identities
разделены по
[`production-secrets-runbook.md`](production-secrets-runbook.md). Recovery
contacts и break-glass material хранятся только в зашифрованном offline
хранилище owner, не в Git или общем password vault.

## Production inventory

`Provider / resource reference` заполняется в закрытом access register до
release. В Git остаются только роль owner, назначение и статус.

| Asset | Production boundary | Access owner / identity | Recovery evidence | Статус |
| --- | --- | --- | --- | --- |
| Git remote и protected CI environment | Source, release tag, build provenance | Product owner / `sosedi-ci` | Independent remote check из [`source-backup.md`](source-backup.md) | Настроить protected production environment |
| Private OCI registry в РФ | Immutable backend/operator/base images по digest | Product owner / CI push + deploy pull identities | Digest и mirror smoke из [`container-images.md`](container-images.md) | Provider/resource reference не назначен — release blocker |
| Compute/reverse proxy в РФ | Backend monolith, operator UI, public Astro, TLS perimeter | Product owner / `sosedi-deploy-prod` | Last-known-good image digest и host config backup | Provider/resource reference не назначен — release blocker |
| PostgreSQL/PostGIS и backups в РФ | Profiles, Items, Bookings, payments/disputes, audit | Product owner / runtime + short-lived migration identities | Encrypted backup IDs и последний restore-drill record | Production resource и restore drill не готовы |
| Redis в закрытой сети РФ | OTP, refresh families, BullMQ | Product owner / `sosedi-backend-prod` | Rebuild procedure; Redis не является единственной durable record | Production resource не назначен |
| Public/private S3 и backups в РФ | Item/handover photos; private evidence/KYC only if enabled | Product owner / prefix-scoped backend identity | Version/backup reference и object restore sample | Основной provider не выбран — release blocker |
| Secret manager в РФ | Runtime/provider credentials and metadata | Product owner / scoped workload identities | Encrypted break-glass copy and rotation record | Provider не назначен — release blocker |
| DNS, domains и TLS | API/operator/public URLs and certificates | Product owner MFA account | Registrar recovery and expiry alerts | Реальные domain/resource references не назначены |
| GlitchTip self-hosted в РФ | Redacted error events and alerts | Product owner / observability admin + client DSN | DB/object backup and test-event record | Не развёрнут — release blocker |
| SMS.ru | OTP send-only integration and spend limit | Product owner / backend send-only key | Provider recovery, quota alert, Exolve contact plan | Production key/live smoke не подтверждены |
| Push providers | FCM/APNs/RuStore eventId-only delivery | Product owner / per-app send identities | Provider credential rotation and device smoke | Store/provider setup не завершён |
| CloudPayments Safe Deal | Два связанных test/live терминала оплаты и выплат только после выбранного payment ADR; offline pilot не имеет live credential | Product owner / dedicated backend identity | `AccumulationId` status и provider reconciliation/export record | Live mode запрещён до payment gate |
| App stores и signing | App Store Connect, Google Play, RuStore; package `ru.sosedi.app` | Product owner / release signing identity | Encrypted signing backup per [`store-readiness.md`](store-readiness.md) | Accounts/internal builds требуют внешнего подтверждения |
| First admin/operator access | MFA admin, least-privilege operator UI | Product owner / named human admin | Recovery codes offline; bootstrap audit | Выполнить по [`first-admin-bootstrap.md`](first-admin-bootstrap.md) |

Незаполненный provider/resource reference не замещается домыслом: это явный
release blocker. Закрытый access register для каждого asset содержит provider
reference, human owner, service identity, scope, MFA, issued/rotated/expires,
revoke procedure и последний access review — без plaintext secret.

## Deploy runbook

1. Создать change record: release/version, Git commit, target и предыдущий image
   digest, migrations, operator, окно, связанные backup IDs и rollback owner.
2. Подтвердить release gates: `make ci` из чистого commit, legal/safety scope,
   закрытые P0, актуальный restore drill, provider live/test mode и MFA.
   Собрать protected release evidence по
   [`production-release-gate.md`](production-release-gate.md) и выполнить
   `make release-gates`; committed example намеренно не проходит.
   Выполнить `make environment-isolation` на трёх protected env files; значения
   и connection strings в change record не копировать.
   Выполнить `make time-sync` на target host; backend readiness отдельно сверит
   часы процесса с PostgreSQL по
   [`time-and-clock-readiness.md`](time-and-clock-readiness.md).
   Выполнить `make production-boundary` и сверить provider firewall export с
   [`production-network-access.md`](production-network-access.md).
3. Убедиться, что production использует российский private registry и exact
   digest. Tag без digest не является deploy artifact.
4. Проверить свежий encrypted PostgreSQL/S3 backup и свободное место. Secret
   values и connection strings в change record не копировать.
5. Запустить одну short-lived migration identity/job. Сначала применять
   backward-compatible expand migration; destructive cleanup — отдельным
   release после перехода всех consumers.
6. Развернуть backend monolith через `make production-release`: current exact
   digest допускается в трафик только после обязательного HTTPS smoke, а провал
   автоматически возвращает previous digest по
   [`production-release-gate.md`](production-release-gate.md). Затем развернуть
   operator/public assets.
7. Помимо автоматического read-only gate выполнить staged authenticated smoke,
   queue/outbox, upload и включённые provider callbacks. OTP проверять только
   утверждённым test contract без случайной SMS реальному пользователю.
8. Проверить alerts/log redaction и записать фактический digest, migration
   result, smoke result и время наблюдения. Alert rules предварительно проверить
   `make alerts-verify`, а delivery — по
   [`monitoring-alert-runbooks.md`](monitoring-alert-runbooks.md). Только после
   этого закрыть change.

## Incident runbook

1. Объявить severity: P0 — утечка/деньги/полная недоступность; P1 — ключевой flow
   или очередь; P2 — деградация с безопасным обходом. Назначить Incident
   commander и единый incident record без ПД/секретов.
2. Сначала ограничить blast radius: закрыть affected entry point/traffic,
   остановить конкретный consumer/job или отозвать credential. Не удалять
   данные и audit evidence.
3. Зафиксировать UTC timeline, release digest, alerts, provider event IDs и
   затронутые data categories. Логи экспортировать только в утверждённое
   хранилище РФ с redaction.
4. Для утечки выполнить emergency revoke из secrets runbook; для integrity
   incident перевести affected writes в безопасный режим и сохранить evidence.
5. Восстановить сервис из известного digest/backup, выполнить readiness и
   business smoke. Privacy/legal owner отдельно решает уведомления и legal hold.
6. После стабилизации устранить root cause, добавить минимальный regression
   check/runbook update и записать owner/due date. Incident закрывается только
   после revoke/recovery verification и наблюдения.

## Rollback runbook

1. Остановить rollout и новые несовместимые writes; сохранить incident/change
   context и текущий digest.
2. Если schema совместима, вернуть предыдущий записанный image digest через
   `make production-rollback` либо эквивалентный provider deploy control plane и
   повторить тот же обязательный readiness/business smoke.
3. Если migration несовместима с предыдущим кодом, не выполнять слепой down
   migration. Оставить совместимый код и сделать forward-fix либо восстановить
   из проверенного backup только по отдельному recovery plan.
4. Для provider/config release вернуть предыдущую versioned configuration
   reference; скомпрометированный credential повторно не активировать.
5. Проверить очереди, webhook replay/idempotency, DB consistency и отсутствие
   mixed-version traffic. Записать фактический digest и результат.

## Review gate

- Inventory review — перед каждым release; access review — ежемесячно.
- Каждый deploy/rollback/incident имеет UTC timestamp, owner, immutable
  artifact references и результат smoke.
- Команды и документы не содержат secret values или широких destructive paths.
- Первый production release запрещён, пока хотя бы один asset со статусом
  `release blocker` не имеет закрытого provider reference и recovery evidence.
