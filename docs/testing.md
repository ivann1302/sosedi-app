# Тестирование Sosedi

## Быстрые и полные проверки

Для повседневной локальной разработки:

```bash
make check
```

Команда запускает lint без изменения файлов, backend unit-тесты, полный Flutter
analyze и Flutter-тесты.

Перед merge:

```bash
make ci
make test-infra-down
```

`make ci` дополнительно проверяет coverage, backend build, поднимает изолированные
PostgreSQL/PostGIS и Redis, применяет миграции и запускает e2e.

## Изолированная test-инфраструктура

Test Compose не использует development-базу:

- PostgreSQL/PostGIS: `localhost:5435`, база `sosedi_test`;
- Redis: `localhost:6380`, логическая база `15`;
- данные находятся в `tmpfs` и исчезают вместе с контейнером.

Команды:

```bash
make test-infra-up
make backend-test-e2e
make test-infra-down
```

Порты и URL можно переопределить:

```bash
make backend-test-e2e \
  TEST_POSTGRES_PORT=15435 \
  TEST_REDIS_PORT=16380 \
  TEST_DATABASE_URL='postgresql://sosedi_test:sosedi_test@localhost:15435/sosedi_test?schema=public' \
  TEST_REDIS_URL='redis://localhost:16380/15'
```

Jest e2e намеренно преобразует только `TEST_DATABASE_URL` и `TEST_REDIS_URL` в
runtime URL. Случайно унаследованный production `DATABASE_URL` не используется.
Очистка состояния дополнительно разрешена только для локальной базы
`sosedi_test` на нестандартном порту и Redis DB 15 на нестандартном порту.

## Coverage baseline

Текущие пороги фиксируют исходную точку, а не желаемое конечное качество:

| Код | Statements | Branches | Functions | Lines |
|---|---:|---:|---:|---:|
| Backend | 49% | 35% | 57% | 49% |
| Flutter | — | — | — | 80% |

Backend-порог проверяет Jest, Flutter-порог — `make mobile-coverage-check`.
После Auth safety-net фактическое покрытие составляет 49,13% строк backend и
83,57% строк Flutter без generated-кода. Пороги оставляют небольшой запас от
шумных изменений форматирования, но не позволяют вернуть покрытие к исходному
уровню.
Порог нельзя снижать для прохождения PR. После добавления очередного набора
осмысленных тестов его нужно поднять до нового устойчивого значения.

Coverage остаётся индикатором регрессии:

- 100% глобального покрытия не требуется;
- сгенерированные Dart-файлы `*.g.dart` и `*.freezed.dart` исключаются из расчёта
  Flutter coverage; простая вёрстка не тестируется ради цифры;
- критические сценарии Auth, Booking, Payments и KYC оцениваются по таблице
  сценариев и branch coverage;
- реальные PostgreSQL/PostGIS и Redis нельзя заменять mock-ами там, где проверяются
  запросы, транзакции, ограничения или конкуренция.

## E2E bootstrap

Production и e2e используют одну функцию `configureApp()`, поэтому тесты проверяют:

- prefix `/api/v1`;
- преобразование и валидацию DTO;
- удаление/отклонение неизвестных полей;
- единый формат ошибок;
- скрытие деталей неожиданных исключений.

Начальный e2e smoke также проверяет подключение API к чистой PostGIS-базе и Redis.

## Auth safety-net

Backend Auth проверяется через настоящий HTTP, PostgreSQL/PostGIS и Redis:

- OTP login → `/auth/me`;
- срок действия, лимиты и блокировка OTP;
- однократное использование OTP и refresh token, включая конкурентные запросы;
- refresh rotation, replay и logout;
- access/refresh token separation;
- актуальные роли, блокировка и soft delete пользователя;
- обязательный JWT subject и единый формат ошибок.

Flutter Auth проверяется на трёх уровнях:

- `AuthService` — payload, parsing, secure storage и mapping ошибок;
- Dio interceptor — Bearer header, single-flight refresh, retry и invalidation
  сессии;
- `AuthController`, GoRouter и widgets — restore/logout, transient offline,
  route guards, формы и сквозной OTP-переход на home.

Временная ошибка сети или `5xx` не удаляет рабочую мобильную сессию. Окончательный
`401/403` очищает токены и переводит приложение на экран входа.

## TDD для новой разработки

Для одного небольшого поведения:

1. описать Given/When/Then и негативный сценарий;
2. написать тест и увидеть ожидаемый RED;
3. добавить минимальную реализацию до GREEN;
4. выполнить refactor без изменения контракта;
5. запустить targeted test, затем `make check`;
6. перед merge запустить `make ci`.

Bugfix всегда начинается с теста, воспроизводящего ошибку. Ожидание теста нельзя
менять только ради зелёного результата.
