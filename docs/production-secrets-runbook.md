# Production secrets runbook

Статус: обязательная процедура до production deploy. Этот документ не содержит
значений секретов и не заменяет provider-specific инструкцию после выбора
хостинга.

Основа: [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html).

## 1. Минимальная модель MVP

- Хранить production-секреты в secret manager выбранного российского
  infrastructure-провайдера. Не строить отдельный Vault/KMS-кластер для MVP.
- Инжектировать секреты при deploy/runtime; не помещать их в Git, Docker image,
  build artifacts, command line, логи, Flutter bundle или общие `.env`-файлы.
- Development, test, staging и production используют разные значения и
  service accounts.
- Один credential принадлежит одному consumer и purpose. Не использовать общий
  «admin key» для backend, CI и ручной работы.
- Человек работает под MFA-аккаунтом; runtime/CI используют отдельные
  non-interactive identities.
- Если provider поддерживает OIDC/короткоживущие credentials, использовать их
  вместо статического CI/deploy token.

Путь секрета: `sosedi/{environment}/{consumer}/{name}`. Рядом хранить только
metadata: owner, purpose, consumer, created/rotated/expires timestamps, provider
reference и status. Значение секрета в документацию не копировать.

## 2. Роли и минимальные права

| Identity | Разрешено | Запрещено |
|---|---|---|
| `sosedi-backend-prod` | Читать только runtime-секреты backend | Создавать/менять секреты, IAM, billing, registry admin |
| `sosedi-migrate-prod` | Подключаться к production DB на время migration и выполнять утверждённый DDL | Постоянный runtime, IAM/provider admin |
| `sosedi-deploy-prod` | Читать image из private registry, обновлять service и проверять health | Читать все secret values, менять IAM/billing |
| `sosedi-ci` | Build/test и push только в нужный repository; production deploy — только protected environment | Интерактивный вход, wildcard project/admin |
| Human owner | MFA, approve issuance/rotation/revocation, emergency access | Использовать service credential как личный |

Для одного разработчика owner и approver временно один человек, но human и
service identities всё равно разделяются. Break-glass credential хранится
зашифрованно отдельно, используется только при incident и ротируется после
каждого использования.

## 3. Инвентарь и порядок ротации

| Группа | Consumer / минимальные права | Ротация |
|---|---|---|
| `DATABASE_URL_RUNTIME` | Backend; CRUD только schema приложения, без DDL/role admin | Создать новый DB login → deploy/readiness → отозвать старый |
| `DATABASE_URL_MIGRATION` | Одноразовый migration job; только нужный DDL | Выдавать на migration window, затем немедленно отзывать |
| `REDIS_URL` | Backend/BullMQ; user `sosedi_runtime`, только выделенная DB/keyspace, без `ACL`, `CONFIG`, `FLUSH*` и admin commands | Новый ACL credential → deploy/queue smoke → revoke |
| `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET` | Только backend; две разные случайные строки | Maintenance rotation; смена отзывает соответствующие sessions. При компрометации также очистить Redis token families |
| `ADMIN_MFA_ENCRYPTION_KEY` | Только backend; отдельные 32 random bytes в base64 для AES-256-GCM TOTP secrets | Ротация требует controlled re-enrollment TOTP; при компрометации отозвать admin sessions и перевыпустить MFA/recovery codes |
| `SMS_API_KEY` | Backend; send-only API, без account/billing admin | Новый provider key → тестовая SMS → revoke |
| `S3_ACCESS_KEY`, `S3_SECRET_KEY` | Backend; только утверждённые bucket/prefix и нужные get/put/delete | Новый key pair → upload/processing/download smoke → revoke |
| YooKassa credentials/webhook secret | Только после ACCEPTED payment ADR; test/live строго раздельно | По provider-процедуре: новый key/webhook → signed smoke → revoke |
| Private OCI registry credential | CI push или production pull — отдельные accounts/repositories | Новый scoped token → push/pull smoke → revoke |
| Deploy SSH/API credential | Только конкретные hosts/project и deploy commands | Предпочитать short-lived; статический ключ заменить → проверить → удалить old authorized key |
| FCM/APNs/RuStore Push credentials | Только нужное приложение и send capability | Новый credential → test eventId push → revoke |
| Apple/Android/RuStore signing private keys | Release signing; encrypted offline backup, доступ только owner/release job | По expiry/provider rules или incident; старый ключ не удалять, пока store migration не подтверждён |
| GlitchTip admin/API credential | Error pipeline/admin; отдельный от mobile DSN | Новый credential → test event → revoke |

`GLITCHTIP_DSN`, MapKit key, bundle ID и package name находятся в клиентском
bundle и не считаются сохраняемыми секретами. Для них применяются минимальные
scope/app restrictions, quota и provider-side revoke.

## 4. Выдача

1. Записать change: environment, purpose, owner, consumer, требуемые actions,
   срок и способ revoke. Значение секрета не записывать.
2. Создать отдельный service account/role с deny-by-default и минимальными
   resource/action/network restrictions.
3. Сгенерировать credential внутри provider/secret manager. Не передавать его
   через чат, issue, email или clipboard history.
4. Разрешить чтение только нужной runtime identity. Людям по умолчанию доступ к
   plaintext не выдавать.
5. Deploy через protected environment, затем выполнить один provider-specific
   smoke и readiness.
6. Записать provider reference, владельца, дату выдачи и следующей проверки.

## 5. Плановая ротация

Проверять metadata ежемесячно. Максимальный возраст reusable runtime/API
credential — 90 дней, если provider не требует меньший срок. Сертификаты и
signing keys ротируются по provider expiry с alert минимум за 30 дней.

Порядок:

1. Создать новую версию с теми же или более узкими правами.
2. Обновить secret reference/runtime и перезапустить только consumer.
3. Проверить readiness и один реальный smoke без вывода credential.
4. Убедиться, что новый credential используется, затем отозвать старый.
5. Наблюдать error/auth metrics и queue минимум один рабочий цикл.
6. Обновить metadata и change record.

Пока старый credential не отозван, допускается rollback на него. После
компрометации старый credential не активировать повторно.

## 6. Emergency revoke

Начать containment сразу после подозрения на утечку.

1. Определить secret, environment, consumers и audit window.
2. Отозвать/disable скомпрометированный credential у provider. Не ждать deploy
   нового значения, если blast radius высокий.
3. Выпустить новый credential с минимальными правами и обновить consumers.
4. Для JWT/Redis отозвать server sessions/token families; для signing/provider
   keys выполнить их специальную revoke/store процедуру.
5. Проверить audit/provider logs на использование старого credential и создать
   incident record без значения секрета.
6. Удалить утечку из активных artifacts/logs. Если секрет попал в Git, считать
   его скомпрометированным даже после удаления строки; историю переписывать
   только отдельным согласованным действием.
7. Проверить readiness, smoke, alerts и закрыть incident только после
   подтверждённого revoke.

## 7. Definition of Done для production

- Network/role contract и проверка описаны в
  [`production-network-access.md`](production-network-access.md); runtime не
  получает migration credential, DB/Redis не имеют public ports.
- У каждого production credential есть owner, consumer, purpose, scope,
  provider reference, last rotation и revoke procedure.
- Runtime, migration, CI/deploy и human identities разделены.
- Fork/PR из недоверенного контекста не получает production secrets.
- Secret values отсутствуют в Git/image/artifacts/logs/mobile bundle.
- Плановая ротация и emergency revoke хотя бы одного non-critical credential
  пройдены как smoke до первого публичного release.
- Доступ к secret manager и break-glass защищён MFA и audit.
