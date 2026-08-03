# UTC и синхронизация системного времени

Технические timestamps хранятся как абсолютные `DateTime`/ISO 8601 значения и
сравниваются в UTC. Production Compose задаёт `TZ=UTC`, а PostgreSQL запускается
с `timezone=UTC` и `log_timezone=UTC`. Локальный календарный день аренды остаётся
отдельным Moscow-calendar domain contract и не меняет технические timestamps.

## Release gate

На каждом production host до deploy и после перезагрузки:

```bash
make time-sync
```

Verifier требует активный и синхронизированный systemd NTP, а также timezone
`UTC`/`Etc/UTC`. Результат записывается в change record с UTC-временем, hostname
и release digest, но без env и connection strings.

Backend readiness дополнительно сравнивает `Date.now()` с PostgreSQL
`clock_timestamp()`. При расхождении больше `MAX_CLOCK_SKEW_MS` (по умолчанию
5000 мс, допустимо 1000–60000) `/api/v1/health/ready` возвращает безопасный 503.
Это не заменяет NTP: readiness только не пускает рассинхронизированный instance
в трафик.

## TTL, jobs и provider callbacks

- Pending booking expiry и upload cleanup принимают явный `now`; проверки
  используют одну и ту же UTC-границу при повторном запуске.
- Redis OTP/refresh TTL задаются относительными секундами. TOTP допускает только
  соседний 30-секундный шаг и запрещает повтор уже использованного шага.
- Booking/calendar даты нормализуются отдельно от технического времени.
- Production payment/provider webhook пока запрещён соответствующим gate. При
  его реализации freshness window должен сравнивать provider timestamp с
  единым server receive time, иметь явный предел прошлого/будущего, replay
  protection и тесты на обе стороны clock skew.

## Incident

Если `make time-sync` или readiness clock check не проходит, instance не вводят
в трафик. Проверяют `timedatectl status`, источник NTP и часы PostgreSQL; ручная
правка timestamps или ослабление порога не является исправлением. После
восстановления синхронизации повторяют readiness и business smoke.
