# Environment and provider isolation

Local, staging и production используют отдельные PostgreSQL databases, Redis
databases/credentials, S3 buckets/access identities, JWT/MFA/metrics secrets и
provider modes. Реальные secret files хранятся вне Git с mode `0600`; файлы в
`ops/environments/*.example` описывают только контракт.

Режимы:

| Environment | Общий mode | SMS | Payment / push |
| --- | --- | --- | --- |
| local | `local` | console/local | fake или disabled |
| staging | `test` | SMS.ru test | test или disabled |
| production | `live` | SMS.ru live | live только после gate, иначе disabled |

Verifier не исполняет env как shell, не печатает значения и требует различия
DB/Redis URLs, JWT/MFA/metrics secrets, S3 buckets и access identities:

```bash
LOCAL_ENV_FILE=/protected/local.env \
STAGING_ENV_FILE=/protected/staging.env \
PRODUCTION_ENV_FILE=/protected/production.env \
make environment-isolation
```

Production ПД запрещено копировать в local/staging. До появления отдельного
reviewed anonymization job оба non-production template используют
`NONPRODUCTION_DATA_POLICY=synthetic-only`. Значение `anonymized` разрешается
только после restore в изолированную сеть, удаления phone/name/address/exact
location/KYC/payment/provider payload и замены object storage synthetic
fixtures; исходная копия немедленно уничтожается по runbook. Один лишь другой
пароль или имя базы не считается обезличиванием.

Production payment/push mode остаётся `disabled`, пока provider/legal gates не
закрыты. Переключение на `live` требует отдельного release change, staged smoke
и повторного verifier; test credentials в production запрещены.
