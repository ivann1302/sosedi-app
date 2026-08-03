# Очистка логов и событий GlitchTip

## Контракт

В diagnostic output запрещены:

- access/refresh/admin JWT, API keys, secrets и пароли;
- OTP, cookies, `Authorization` и `X-CSRF-Token`;
- телефоны, точные адреса и координаты;
- KYC/passport/selfie payload;
- card/payment/provider payload;
- presigned upload/download URL и их подписи.

Доменные ID, безопасные status/error code и технический контекст сохраняются.
Нельзя помещать ПД под произвольным «безопасным» ключом: sanitizer дополняет
минимизацию данных в месте создания события, а не заменяет её.

## Backend

`RedactingLogger` передаётся в `NestFactory` и очищает message и optional params
для всех Nest log levels. `HttpExceptionFilter`, photo worker и console SMS
fallback не выводят raw exception, телефон или OTP.

Чтобы console SMS оставался пригоден для локального входа без утечки в log,
используется явный `DEV_SMS_OTP_CODE` из локального env. Он принимается только
вне `NODE_ENV=production`; production всегда генерирует случайный OTP.

`redactSensitiveData()` рекурсивно обрабатывает object/array/map/set/error и
защищён от cyclic object. Для неструктурированного текста дополнительно
удаляются Bearer/JWT, российские телефоны, OTP/cookie и signed URL.

## Mobile и GlitchTip

GlitchTip включается только непустым `--dart-define=GLITCHTIP_DSN=...`.
Разрешён только HTTPS DSN self-hosted сервера; `sentry.io` явно отклоняется.
Без DSN SDK не инициализируется.

Перед отправкой:

- `sendDefaultPii=false`, request body и tracing выключены;
- user, request, cookies, attachments, screenshot и view hierarchy удаляются;
- весь serialized event рекурсивно очищается;
- stack сохраняет filename/function/line, но теряет absolute path, source
  context и local variables.

Пример release-конфигурации:

```bash
flutter build apk \
  --dart-define=GLITCHTIP_DSN=https://public-key@errors.example.ru/1 \
  --dart-define=APP_ENVIRONMENT=production \
  --dart-define=APP_RELEASE=sosedi@0.1.0+1
```

Client-side redaction не заменяет server-side scrubbing и retention в
self-hosted GlitchTip. Их deployment/smoke выполняются в отдельном
production-readiness gate.
