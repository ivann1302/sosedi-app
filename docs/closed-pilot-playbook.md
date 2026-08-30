# Закрытый локальный пилот

Этот playbook помогает воспроизводимо показать и проверить текущий MVP до
подключения внешних release gates. Он не открывает публичную аренду и не заменяет
юридическое, store, provider или device-подтверждение из `MVP_CHECKLIST.md`.

## Что готово локально

- гостевой каталог, карточка вещи и auth-on-intent;
- один аккаунт может брать и сдавать вещи;
- guarded fixture seed без удаления существующих данных;
- бронирования, чат, акты, inbox, support, moderation и reviews проверяются
  автоматическими unit/widget/e2e-тестами;
- 29 screenshot-экранов связаны в `docs/app-user-paths.html`;
- одна команда запускает полный локальный pilot smoke и всегда выключает
  изолированные test-контейнеры.

Не готовы без внешнего участия: настоящие MapKit/push, signed store builds,
утверждённые legal documents, production SMS/S3, Safe Deal, KYC, реальные
платежи и smoke на физических устройствах.

## Предварительные условия

1. Docker, Node.js/npm и Flutter установлены.
2. Зависимости `backend`, `operator`, `public-web` и `mobile` уже установлены из
   lock-файлов.
3. `backend/.env` создан локально и содержит loopback `DATABASE_URL`. Не
   направлять pilot seed на staging или production.
4. Для ручного локального OTP использовать только:

   ```dotenv
   NODE_ENV=development
   SMS_PROVIDER=console
   DEV_SMS_OTP_CODE=123456
   ```

   Console provider не пишет телефон или OTP в лог. Код задаётся разработчиком
   через локальный env и запрещён в production.

## Локальные данные

```bash
make pilot-seed
```

Команда сначала проверяет явный opt-in, `NODE_ENV=development` и loopback
PostgreSQL, затем применяет миграции, канонический category seed и идемпотентно
создаёт только собственные fixtures. Она ничего не удаляет.

Синтетические аккаунты:

- владелец: `+7 999 000-10-01`;
- арендатор: `+7 999 000-10-02`.

Seed создаёт шесть approved объявлений в разрешённых launch-категориях, одно
объявление `PENDING` и два избранных объявления арендатора. Точные fixture-адреса
локальные и не соответствуют реальным людям.

## Ручной запуск

В отдельных терминалах:

```bash
make backend-dev
```

```bash
cd mobile
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Для Android emulator можно не задавать `API_BASE_URL`: debug default использует
`10.0.2.2`. Operator UI при необходимости запускается командой
`make operator-dev`; первый admin создаётся только по процедуре
`docs/first-admin-bootstrap.md`, без default credentials.

Остановка локальной инфраструктуры:

```bash
make infra-down
make test-infra-down
```

## Автоматический smoke

```bash
make pilot-smoke
```

Команда последовательно выполняет:

1. `make check`;
2. все backend e2e против отдельной `sosedi_test` БД и Redis DB 15;
3. регенерацию 29 route screenshots;
4. проверку всех ссылок `docs/app-user-paths.html`;
5. `make test-infra-down` даже после ошибки предыдущего этапа.

Smoke не использует production credentials, не отправляет SMS/push и не
проводит деньги.

## Golden path 1 — найти вещь и начать бронь

Участник не получает предварительных подсказок.

1. Открыть приложение без SMS.
2. Пропустить onboarding и попасть в `Найти`.
3. Найти подходящую вещь поиском, категорией или районом.
4. Открыть карточку и объяснить вслух, где показаны цена, состояние и район.
5. Нажать основной booking CTA.
6. Пройти console OTP и убедиться, что безопасный intent восстановился.
7. Дойти до выбора дат и полного расчёта.

Критерий локального walkthrough: участник доходит до подходящей карточки без
помощи. Booking submit остаётся fail-closed, пока mobile не собран с точными
утверждёнными versioned offer/rental-rules URL; не подставлять фиктивные
production-документы ради демонстрации.

## Golden path 2 — подготовить объявление

1. Войти локальным аккаунтом владельца.
2. Открыть `Сдать` → `Новое объявление`.
3. Добавить до пяти фото, увидеть thumbnails, выбрать обложку и удалить лишнее.
4. Заполнить описание, категорию, состояние, комплект и цену.
5. Дойти до места/доступности и объяснить границу публичного района и приватного
   адреса.
6. Проверить локальный draft/back/resume.

Критерий локального walkthrough: участник проходит первые два шага без помощи и
понимает третий. Полный upload/submit на живом устройстве требует выбранного
S3-провайдера и общего MapKit location control; до этих gates использовать
`PENDING` fixture и screenshot-карту, а не объявлять provider flow готовым.

## Operator/support проверка

- проверить очередь `PENDING` и audit только через capability-scoped operator;
- не использовать общий admin JWT или default password;
- показать обычное `GENERAL` обращение, назначение, ответ и закрытие;
- не обещать refund и не выполнять финансовое решение до dispute/payment ADR;
- не копировать телефон, адрес, evidence URL или содержимое обращения в рабочие
  заметки.

## Карта наблюдения usability

Для каждого участника сохранить только псевдоним и агрегируемые результаты:

| Поле | Значение |
|---|---|
| Participant | Случайный код, без телефона/ФИО |
| Device/build | Модель, ОС, build number |
| Path | Найти/начать бронь или подготовить объявление |
| Start/end | Время начала и завершения |
| Completed unaided | Да/нет |
| First blocker | Экран и наблюдаемое действие, без интерпретации |
| Permission/offline | Какой сценарий встретился |
| Critical quote | Короткий пересказ, не запись голоса |

После минимум пяти новых пользователей считать медиану до карточки и до submit
объявления. Пороговые решения и список районов меняет владелец продукта, а не
fixture/API. User-level marketing export не создавать.

## Ежедневный чек пилота

- проверить API/readiness и доступность выбранных обязательных providers;
- проверить moderation/support queue и обращения старше SLA;
- найти stuck `PENDING/CONFIRMED/ACTIVE/RETURNED`, не менять состояния напрямую в
  БД;
- проверить отчёты safety/privacy и не переносить evidence в публичные каналы;
- зафиксировать incident owner и ссылку на применимый runbook;
- после работы остановить test-инфраструктуру и не сохранять реальные данные в
  fixture seed или screenshots.
