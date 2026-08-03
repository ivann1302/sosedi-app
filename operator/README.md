# Sosedi Operator

Минимальный закрытый React/Vite UI для `SUPPORT` и `MODERATION`.
`SUPPORT` видит только обычные обращения; users, moderation и reports доступны
в навигации только с `MODERATION`, поверх обязательных backend guards.

```bash
npm ci
make operator-dev
make operator-build
```

Vite проксирует `/api` на `http://localhost:3000`. После SMS login access JWT
живёт только в React memory до TOTP/recovery step-up. Дальше browser использует
только opaque admin session и CSRF cookies с `credentials: include`;
`localStorage` содержит лишь стабильный installation UUID для OTP rate limit.
Интерфейс завершает сессию после 5 минут бездействия, не продлевает серверный
hard TTL и немедленно возвращает к login при `401` после отзыва доступа.
Logout очищает access token, профиль сессии, users/items/reports, support thread
и выбранные private-файлы из React memory, отменяя in-flight API/S3 upload;
presigned download URL не сохраняется.

Очередь `GENERAL` показывает assignee, детерминированный SLA/priority и только
безопасный booking context (`bookingId`/reason без адреса, контакта и денег).
Оператор может взять обращение и ответить; refund/payout/dispute actions
намеренно отсутствуют до ADR и отдельной `FINANCE` capability.

Production web server должен использовать [nginx.conf](nginx.conf), который
задаёт CSP, `frame-ancestors 'none'`, `X-Frame-Options: DENY`, no-referrer и
no-store. Reports, KYC, disputes и payments не входят в shell до своих roadmap
этапов.
