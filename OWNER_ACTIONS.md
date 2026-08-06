# Что нужно сделать владельцу проекта

Дата актуализации: 06.08.2026.

Этот файл — практическая инструкция для владельца Sosedi. Он не меняет порядок
и статусы roadmap. Источник истины — [`MVP_CHECKLIST.md`](MVP_CHECKLIST.md), а
подробные принятые решения находятся в [`docs/adr/`](docs/adr/).

## Правила безопасной работы

- Не отправлять в чат и не коммитить пароли, API keys, private keys, recovery
  codes, токены registry, Apple/Google/RuStore credentials и содержимое `.env`.
- Секреты хранить в password manager, защищённом CI environment или secret
  manager. Для локальных файлов использовать путь вне Git и права `0600`.
- Для каждого сервиса включить MFA и сохранить recovery codes в отдельной
  зашифрованной offline-копии.
- Для автоматики создавать отдельные service identities с минимальными правами.
  Не использовать личный admin token в CI или production.
- Codex сообщать только название провайдера, имя ресурса, несекретный URL,
  регион, названия env variables и путь к защищённому файлу. Значения секретов
  сообщать не нужно.

## Что сделать сначала

Текущие ближайшие внешние блокеры:

1. российский private OCI registry;
2. независимая от GitHub резервная копия Git-репозитория;
3. аккаунты магазинов и signing;
4. юридические и платёжные решения;
5. production-инфраструктура в РФ.

Пока выполняются эти действия, Codex может самостоятельно исправить
недетерминированные booking-тесты и повторно выполнить `make ci`.

## 1. Создать private OCI registry в РФ

### Что это и зачем

OCI registry — это закрытое хранилище готовых серверных программ в виде Docker
images. Проще говоря, там лежат упакованные версии backend, PostgreSQL, Redis и
других компонентов, из которых запускается production.

Российское зеркало нужно, чтобы запуск и обновление Sosedi не остановились, если
Docker Hub или другой зарубежный источник временно недоступен. Раздельные
доступы нужны для безопасности: CI может загружать новые images, а production —
только скачивать уже проверенные.

### Что сделать

- [ ] Выбрать провайдера с private OCI/Docker registry в российском регионе.
- [ ] Включить MFA для личного аккаунта владельца.
- [ ] Создать приватный project/namespace для Sosedi.
- [ ] Получить prefix вида `registry.example.ru/sosedi` без `https://` и без
  завершающего `/`.
- [ ] Создать identity `sosedi-ci` с `pull + push` только в этот namespace.
- [ ] Создать отдельную identity `sosedi-production-pull` только с `pull`.
- [ ] Сохранить credentials в CI/secret manager, не в репозитории.
- [ ] Проверить, что billing, recovery contact и MFA принадлежат владельцу.

### Что сообщить Codex

```text
OCI provider: <название>
OCI region: <регион РФ>
OCI_REGISTRY_PREFIX: <registry-host/project>
CI credential location: <название CI secret или путь, без значения>
Production pull credential location: <название secret или путь, без значения>
```

### Что затем сделает Codex

Codex выполнит вход через provider CLI/Docker credential helper, затем:

```bash
OCI_REGISTRY_PREFIX=<registry-host/project> make container-mirror
OCI_REGISTRY_PREFIX=<registry-host/project> make production-images
```

Скрипт зеркалирует Node, PostGIS, Redis и GlitchTip и сверяет исходный и целевой
digest. После появления compute Codex проверит сборку и deploy при
недоступности внешнего registry. Подробности: [`docs/container-images.md`](docs/container-images.md).

## 2. Создать независимую резервную копию Git

### Что это и зачем

Git-репозиторий содержит исходный код и историю изменений проекта. Сейчас
рабочая копия хранится на GitHub. Второй приватный репозиторий у другого
провайдера нужен как независимая резервная копия.

Если GitHub-аккаунт заблокируют, удалят или он станет недоступен, проект можно
будет полностью восстановить вместе с ветками, тегами и историей. Простого
архива на том же компьютере недостаточно: поломка или потеря компьютера затронет
и код, и такой «backup» одновременно.

### Что сделать

- [ ] Выбрать Git-провайдера с hostname, отличным от `github.com`.
- [ ] Создать приватный пустой репозиторий для backup.
- [ ] Включить MFA владельца и сохранить recovery codes.
- [ ] Создать repository-scoped credential, который может писать только в backup
  repository.
- [ ] Настроить credential через provider CLI или Git credential helper. Не
  добавлять token в remote URL.
- [ ] Передать Codex несекретный clone URL и расположение credential.

### Что сообщить Codex

```text
Git backup provider: <название>
Backup clone URL: <URL без token>
Credential location: <название secret/helper, без значения>
Default branch: main
```

### Что затем сделает Codex

```bash
git remote add backup <private-independent-repository-url>
git push backup --all
git push backup --tags
make git-backup-verify
```

Затем будет выполнен отдельный test clone в temporary directory. В evidence
попадут только provider, дата, commit SHA и результат восстановления. Критерии:
[`docs/source-backup.md`](docs/source-backup.md).

## 3. Подготовить аккаунты магазинов

### Что это и зачем

App Store Connect, Google Play Console и RuStore Console — кабинеты, через
которые приложение подписывается, проверяется и становится доступно тестерам и
пользователям. Создание аккаунтов и проверка владельца могут занять заметное
время, поэтому это делается до завершения всей разработки.

Цифровая подпись подтверждает, что новую версию выпустил именно владелец Sosedi.
Без signing keys нельзя загрузить release-сборку, а при потере ключей можно
потерять возможность безопасно обновлять уже опубликованное приложение.

Во всех магазинах использовать идентификатор приложения `ru.sosedi.app`.

### Apple Developer и App Store Connect

- [ ] Проверить, что Apple Developer Program имеет статус `Active`.
- [ ] Записать expiration date и тип membership: individual или organization.
- [ ] Проверить доступный способ продления и фактический платежный метод.
- [ ] Убедиться, что вы являетесь Account Holder или имеете его подтверждение.
- [ ] Создать App ID и приложение в App Store Connect с bundle ID
  `ru.sosedi.app`.
- [ ] Создать distribution certificate и provisioning profile.
- [ ] Сохранить certificate/private key и recovery metadata в зашифрованной
  offline-копии.

Codex нужны только статус, expiration date, Team ID и путь к защищённым signing
files. Apple Account, пароль и private key в чат передавать нельзя.

### Google Play Console

- [ ] Подтвердить рабочий доступ к Play Console.
- [ ] Создать приложение с package name `ru.sosedi.app`.
- [ ] Включить Play App Signing.
- [ ] Согласовать защищённое место для Android upload keystore и его backup.
- [ ] После сборки загрузить AAB во внутренний тестовый трек.

### RuStore Console

- [ ] Создать приложение с package name `ru.sosedi.app`.
- [ ] Проверить требования к подписи и зарегистрировать upload certificate.
- [ ] После сборки загрузить smoke-версию и пройти доступную проверку.

После создания приложений Codex подготовит signing-конфигурацию, соберёт
checksum-bound AAB/IPA и даст точный порядок загрузки. Полный gate описан в
[`docs/store-readiness.md`](docs/store-readiness.md).

## 4. Зафиксировать legal и business-решения

### Что это и зачем

Этот шаг определяет правила работы сервиса: кто заключает договор аренды, за что
отвечает площадка, что происходит при отмене, повреждении или споре и как
обрабатываются персональные данные.

Код может только исполнять уже принятые правила. Если сначала реализовать
неутверждённый сценарий, после юридической проверки придётся переделывать
бронирование, платежи, документы и интерфейс. Утверждённые версии документов
также нужны магазинам приложений и должны сохраняться в каждой Booking.

Эти решения должен подтвердить владелец с профильным российским специалистом.
Codex может подготовить вопросы, ADR и встроить утверждённые правила в код, но не
может заменить юридическое заключение.

### Что нужно утвердить

- [ ] Роль Sosedi: площадка/посредник, стороны договора аренды и границы
  ответственности.
- [ ] Возраст пользователя и eligibility.
- [ ] Подтверждение права владельца распоряжаться вещью.
- [ ] Правила состояния, комплектности и безопасной передачи.
- [ ] Отмена до и после подтверждения: кто отменяет, deadline, причина, refund и
  возможная комиссия.
- [ ] No-show, неисправность, ранний/поздний возврат, потеря и повреждение.
- [ ] Срок открытия dispute, допустимые evidence и решения.
- [ ] Когда участникам показываются точный адрес и контакт и когда доступ
  закрывается после возврата.
- [ ] Retention, legal hold, экспорт и закрытие аккаунта.
- [ ] Публичный support-контакт и SLA.
- [ ] Финальные тексты оферты, правил аренды и privacy/consent.

### Что передать Codex после согласования

```text
Offer file: <путь к утверждённому файлу>
Offer version/effective date: <версия и дата>
Rental rules file: <путь>
Rental rules version/effective date: <версия и дата>
Privacy/consent file: <путь>
Privacy version/effective date: <версия и дата>
Support public contact: <email или URL>
Legal approval reference: <несекретная ссылка/номер закрытой записи>
```

Codex перенесёт утверждённые версии в Astro-сайт, настроит versioned URLs,
обновит mobile config и проверит immutable acceptance snapshot в Booking.

## 5. Выбрать платёжный сценарий

### Что это и зачем

Нужно заранее определить, проходят ли деньги через Sosedi или пользователи
рассчитываются напрямую при передаче вещи. От этого зависят договоры, комиссия,
возвраты, чеки, идентификация владельца и объём разработки.

Одновременно реализовывать оба варианта нельзя: это усложнит MVP и создаст риск
ошибок с реальными деньгами. Поэтому выбирается один сценарий, а ненужная ветка
не включается в release.

Владелец выбрал направление монетизации: Sosedi получает комиссию с завершённой
аренды, а деньги между арендатором и владельцем проводит provider Safe Deal.
Предварительный выбор записан в `PROPOSED` ADR-0005; production остаётся
выключен до индивидуального тарифа, договора и legal/accounting approval.

### Резервный вариант — быстрый пилот

`PAY_ON_HANDOVER`: пользователь платит владельцу при передаче вещи, Sosedi не
принимает деньги и имеет комиссию 0%.

Это минимальный технический путь к пилоту. Online payment, payout, чеки и
платёжный KYC в Sosedi не включаются.

### Выбранное направление — монетизированный Safe Deal

До разработки потребуются:

- [ ] письменное подтверждение ЮKassa о доступности подходящей «Безопасной
  сделки» для выбранной P2P-модели;
- [ ] условия onboarding и идентификации частного получателя;
- [ ] схема hold/capture/refund/payout и ограничения сроков сделки;
- [ ] согласованная комиссия и момент получения дохода Sosedi;
- [ ] налоговая модель и онлайн-касса;
- [ ] официальный webhook/API contract и test environment;
- [ ] решение о KYC: предпочтительно `PROVIDER_MANAGED`, если provider закрывает
  необходимую идентификацию без передачи паспорта/селфи в Sosedi.

### Что сообщить Codex

```text
Payment scenario: SAFE_DEAL
Owner approval reference: ADR-0005 (PROPOSED)
Legal approval reference: <ссылка/номер>
YooKassa commercial offer/approval reference: <ссылка/номер>
T-Bank commercial offer reference: <ссылка/номер>
KYC decision: PROVIDER_MANAGED / LOCAL_KYC
```

Не создавать и не передавать production YooKassa credentials до закрытия этого
gate.

## 6. Подготовить public domain и legal-сайт

### Что это и зачем

Domain — это постоянный адрес сервиса в интернете. Public legal-сайт — простые
страницы с офертой, правилами аренды, privacy, поддержкой и инструкцией удаления
аккаунта. Эти страницы открываются без входа в приложение.

Ссылки нужны пользователям и магазинам приложений до публикации. HTTPS защищает
страницы от подмены по пути. Отдельный статический сайт остаётся доступным, даже
если основной backend временно не работает.

- [ ] Выбрать основной public domain.
- [ ] Определить HTTPS URL для API, operator UI и документов.
- [ ] Выбрать российский static hosting или compute для Astro-сайта.
- [ ] Настроить DNS, TLS и recovery владельца домена.
- [ ] После legal approval добавить URL оферты, правил, privacy, support и
  account deletion в App Store Connect, Google Play и RuStore.

Пример структуры, а не требование купить именно эти имена:

```text
API_BASE_URL=https://api.<domain>/api/v1
Public documents=https://docs.<domain>/documents/...
Operator UI=https://operator.<domain>
```

Codex настроит deploy, security headers, smoke обязательных страниц и проверку
точного version segment в release config.

## 7. Подготовить Yandex MapKit

### Что это и зачем

Yandex MapKit — готовый компонент Яндекса для показа карты внутри мобильного
приложения. API key сообщает сервису, какое приложение обращается к карте, а
ограничения ключа не позволяют постороннему использовать оплачиваемый лимит
Sosedi.

Оценка DAU нужна для понимания будущей нагрузки и стоимости. Согласие на точную
геолокацию нужно потому, что местоположение пользователя относится к
чувствительным данным. Приложение должно объяснить цель и продолжать работать в
ограниченном режиме, если пользователь откажет.

Этот этап начинается только после закрытия Store readiness.

- [ ] Создать отдельный MapKit API key для Sosedi.
- [ ] Ограничить ключ package/bundle ID `ru.sosedi.app` и доступными signing
  restrictions.
- [ ] Записать ожидаемый DAU, бесплатный лимит и допустимый месячный бюджет.
- [ ] Утвердить текст цели, минимизации, срока хранения и согласия на точную
  геолокацию.
- [ ] Сохранить ключ в CI secrets, не в Dart-коде и не в Git.

Codex нужны имя CI secret, ограничения ключа, DAU/бюджет и утверждённый текст
consent. После этого он реализует `features/map`, разрешения, маркеры,
кластеризацию, фильтр радиуса и device smoke.

## 8. Выбрать production-инфраструктуру в РФ

### Что это и зачем

Production-инфраструктура — это реальные серверы и хранилища, на которых будет
работать доступный пользователям сервис. Backend обрабатывает запросы,
PostgreSQL хранит основные данные, Redis — временные коды и сессии, S3 — фото,
а мониторинг сообщает о сбоях.

Ресурсы с персональными данными выбираются в РФ. Разделение доступов, закрытая
сеть, резервные копии и мониторинг нужны, чтобы одна ошибка или украденный ключ
не привели к полной утечке или потере проекта.

Нужно выбрать реальные ресурсы; большую часть технической настройки затем
выполнит Codex.

- [ ] Compute/reverse proxy в РФ.
- [ ] PostgreSQL 15+ с PostGIS и закрытой сетью.
- [ ] Redis с ACL и без публичного порта.
- [ ] Один основной S3-compatible provider в РФ: Selectel или Yandex Object
  Storage.
- [ ] Независимая российская destination для зашифрованных backup.
- [ ] Secret manager или защищённое хранилище production secrets.
- [ ] Prometheus/Alertmanager/Blackbox/node exporters.
- [ ] PostgreSQL/Valkey и SMTP для self-hosted GlitchTip в РФ.
- [ ] DNS/TLS и закрытый доступ к operator UI.

### Для каждого ресурса записать

```text
Provider/resource name:
Russian region:
Human owner:
Service identity name:
Credential scope:
MFA/recovery configured: yes/no
Secret location, without value:
Backup/revoke procedure reference:
```

Codex настроит production Compose/provider adapter, закрытую сеть,
least-privilege credentials, backup/restore drill, мониторинг, alerts,
GlitchTip, immutable deploy и rollback. Полный inventory:
[`docs/production-operations-runbook.md`](docs/production-operations-runbook.md).

## 9. Создать provider-аккаунты

### Что это и зачем

Provider-аккаунты дают Sosedi отдельные внешние функции: SMS.ru отправляет код
входа, FCM/APNs/RuStore доставляют уведомления, а S3 хранит фотографии. Сам код
приложения не может выполнять эти задачи без созданных кабинетов и ограниченных
ключей доступа.

Для каждого провайдера используется отдельный минимальный доступ. Если один
ключ утечёт, его можно отозвать, не меняя пароль владельца и не открывая доступ
к billing или остальным системам.

### SMS.ru

- [ ] Создать production account владельца с MFA/recovery.
- [ ] Получить send-only API key без billing/admin прав.
- [ ] Настроить лимит расходов и уведомления об исчерпании квоты.
- [ ] Сохранить key как `SMS_API_KEY` в secret manager.

### Push

- [ ] Создать Firebase project для Google Play-сборки.
- [ ] Настроить APNs key/certificate для iOS и связать с FCM.
- [ ] Создать RuStore Push project для Android без GMS.
- [ ] Создать отдельные send identities и сохранить credentials в secret manager.

Codex проверит, что push payload содержит только непрозрачный `eventId`, и
выполнит smoke на реальных устройствах.

### S3

- [ ] Создать отдельные public/private/quarantine buckets или утверждённое
  эквивалентное разделение.
- [ ] Включить versioning/retention согласно документации.
- [ ] Создать prefix/bucket-scoped runtime identity.
- [ ] Создать отдельные backup и restore identities.

Codex не нужны secret values. Нужны endpoint, region, bucket names и места, где
хранятся соответствующие secrets.

## 10. Подготовить реальные устройства и финальные smoke

### Что это и зачем

Smoke-проверка — это короткое прохождение главных функций перед release:
установить приложение, войти, создать объявление, забронировать вещь и получить
уведомление. Она подтверждает, что компоненты работают вместе не только в
автоматических тестах, но и на настоящем телефоне.

Нужны разные устройства, потому что Google Play, RuStore, FCM и APNs используют
разные пути доставки. Проверка через российскую сеть дополнительно выявляет
зависимости, которые работают у разработчика, но недоступны будущему
пользователю.

- [ ] Android с GMS и доступом к Google Play internal track.
- [ ] Android без GMS с RuStore.
- [ ] iPhone с TestFlight и APNs.
- [ ] Российская мобильная/домашняя сеть для финального smoke.
- [ ] Тестовые номера телефона, которыми владеет проект.
- [ ] Назначенный первый оператор/moderator с MFA.

Codex подготовит сценарий проверки и будет вести по нему, но вход в личные
store-аккаунты, подтверждение платежей и физические действия на устройствах
выполняет владелец.

## Как сообщить Codex, что готово

Не нужно ждать завершения всего списка. После каждого готового внешнего ресурса
отправить короткое сообщение:

```text
Готов этап <номер>.
Provider/resource: <название>
Region: <регион>
Public identifier/URL: <без credentials>
Secret location: <имя secret или путь, без значения>
Evidence location: <ссылка/путь без ПД и секретов>
Можно выполнять техническую проверку и закрывать соответствующий пункт checklist.
```

Рекомендуемый ближайший порядок:

1. OCI registry.
2. Независимый Git backup.
3. Apple Developer, Google Play и RuStore.
4. Legal-тексты и выбор `PAY_ON_HANDOVER`/`SAFE_DEAL`.
5. Domain и public legal site.
6. MapKit.
7. Production infrastructure и provider accounts.
8. Store/device/release smoke.
