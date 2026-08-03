# Bootstrap первого администратора

Первый production-admin создаётся только из защищённой operational-среды с
прямым доступом к production PostgreSQL. Публичного HTTP endpoint, пароля по
умолчанию и возможности повысить роль через Users API нет.

## Перед запуском

1. Сделать backup БД и проверить, что `DATABASE_URL` указывает на нужную среду.
2. Выбрать существующий активный номер либо новый российский номер, который
   контролирует назначенный оператор.
3. Выдать только нужные сейчас capabilities: `MODERATION`, `SUPPORT` или обе.
   `KYC_REVIEW` и `FINANCE` этим bootstrap намеренно не выдаются.
4. Передать значения как одноразовые env процесса, не сохранять их в `.env`,
   shell history, CI variables длительного действия или ticket.

```bash
ADMIN_BOOTSTRAP_CONFIRM=CREATE_FIRST_ADMIN \
ADMIN_BOOTSTRAP_PHONE='+79991234567' \
ADMIN_BOOTSTRAP_CAPABILITIES='MODERATION,SUPPORT' \
make backend-admin-bootstrap
```

Команда берёт PostgreSQL advisory lock, проверяет отсутствие любого `ADMIN`,
нормализует телефон, создаёт или повышает только активного пользователя и пишет
`FIRST_ADMIN_BOOTSTRAPPED` в audit log без телефона. Повторный и конкурентный
запуск отклоняются. Если повышается существующий пользователь, его текущие
сессии отзываются через увеличение `sessionVersion`.

После запуска удалить одноразовые env из operational-сессии, проверить audit
record и выполнить обычный SMS login. До первого admin step-up:

1. Вызвать `POST /api/v1/admin/session/totp/setup` с access token.
2. Добавить полученный `otpauthUri` в authenticator и подтвердить кодом через
   `POST /api/v1/admin/session/totp/confirm`.
3. Сохранить показанные один раз recovery codes в защищённом offline-хранилище.

TOTP secret хранится в БД и временно в Redis только в зашифрованном виде,
recovery codes — только как SHA-256 хеши. Каждый TOTP time-step и recovery code
принимается один раз. Повторный SMS OTP не выдаёт admin-сессию.

Следующих администраторов нельзя создавать этой командой: нужен будущий
capability-scoped operator workflow с MFA и audit.
