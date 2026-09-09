# Локальное preview промосайта и public web — 09.09.2026

Источник лендинга: `/Users/ivan/projects/sosedi`; владелец подтвердил актуальность.
Изменения сохранены в исходном проекте. Сборки проверялись в изолированной копии
`/private/tmp/sosedi-preview.ZRjcyH/verified-landing` с зависимостями из lock-файла.

## Что изменено

- Header/home: убраны переходы в отсутствующий блог и показ секции его карточек.
- Footer: контакты ведут на `/support/`, документы — на существующие versioned
  Astro routes; вместо отсутствующего sitemap добавлено удаление аккаунта.
  Между Next.js и Astro используются обычные HTML-ссылки. Якоря подвала ведут
  на главную и работают со страницы `/business/`.
- Business CTA использует утверждённый email `sosedi.rs@yandex.ru`.
- Metadata лендинга ссылается на общий знак `/logo/sosedi-mark-orange.svg`:
  браузер больше не запрашивает отсутствующий favicon.
- `scripts/assemble-public-site.mjs` объединяет готовые Next/Astro outputs
  только в новую папку, запрещает конфликт путей, сохраняет главную лендинга.
- `ops/public-site/Caddyfile` раздельно задаёт CSP: Astro и его 404 запрещают
  scripts/connect/forms; landing допускает собственную Next-гидратацию и
  inline styles/scripts. Все ответы preview имеют `noindex, nofollow`.

Caddy используется для локальной проверки настоящих HTTP-заголовков. Это не ADR
о production-веб-сервере и не дополнительный backend приложения. Конфигурация
слушает HTTP :8080. По решению владельца сайт остаётся на SprintHost;
план переноса в Timeweb отменён. Эквивалентные headers на SprintHost ещё нужно
настроить и проверить.

## Проверки

- Next: `npm run lint`, `npm run typecheck`, `npm run build:static` — passed.
- Astro: `make public-web-check` — passed, включая smoke восьми маршрутов.
- Assembly: конфликт путей отклонён, повторная запись в существующий output
  отклонена с сохранением его содержимого.
- Caddy 2.11.4: validate passed; image зафиксирован по digest в команде ниже.
- `make public-site-smoke PUBLIC_SITE_URL=http://127.0.0.1:4175` — passed:
  9 маршрутов, внутренние ссылки/assets/anchors, CSP/headers и 404.
  До исправлений тот же smoke обнаружил missing routes/anchors/headers.
- Chrome на 320/390/1440 px: Next hydration, переходы landing → business →
  support → account-deletion → landing и Next client navigation прошли;
  ошибок console/runtime и горизонтального переполнения нет.
- Скриншоты: `/private/tmp/sosedi-preview-browser/`; просмотрены первые экраны
  landing (320/1440 px) и support (320/1440 px). На 320 px существует наложение
  hero-иллюстрации на текст; перед release нужна отдельная UI-правка. Отсутствие
  горизонтального overflow не означает, что весь исходный дизайн принят.
- Независимое ревью не нашло существенных дефектов в рамках этих изменений.

## Запуск и повторная сборка

Текущее preview: `http://127.0.0.1:4175/`. Статические файлы:
`/private/tmp/sosedi-preview.ZRjcyH/site-final`. Контейнер:
`sosedi-public-preview-20260909-final`. Старое preview :4174 устарело.

После установки зависимостей через `npm ci` и выполнения `npm run build:static`
в проекте лендинга, из `sosedi-app`:

```sh
make public-web-check
preview_dir=$(mktemp -d /private/tmp/sosedi-public.XXXXXX)
make public-site-assemble LANDING_OUTPUT=/Users/ivan/projects/sosedi/out PUBLIC_SITE_OUTPUT="$preview_dir/site"
docker run -d --name sosedi-public-preview --read-only \
  --cap-drop ALL --cap-add NET_BIND_SERVICE --security-opt no-new-privileges \
  --tmpfs /data --tmpfs /config -p 127.0.0.1:4176:8080 \
  --mount "type=bind,src=$preview_dir/site,dst=/srv,readonly" \
  --mount "type=bind,src=$PWD/ops/public-site/Caddyfile,dst=/etc/caddy/Caddyfile,readonly" \
  caddy@sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648
make public-site-smoke PUBLIC_SITE_URL=http://127.0.0.1:4176
docker stop sosedi-public-preview
docker rm sosedi-public-preview
```

NET_BIND_SERVICE нужен из-за file capability бинарника Caddy: с `--cap-drop ALL`
без него exec завершается `operation not permitted` даже на порту 8080.
Образы/готовый артефакт до production должны быть сохранены в РФ согласно §0.1;
команда выше предназначена для local preview. Next/font скачивает шрифты при
build; deploy готовой статики их повторного скачивания не требует.

## Следующий шаг

Проверить текущую конфигурацию SprintHost и подготовить размещение Astro pages
рядом с лендингом на `sosedi-app.ru`. Проверить routes и раздельные security
headers в тестовом размещении; сохранить текущие файлы/конфигурацию для rollback
обновления. Перенос в Timeweb отменён владельцем 09.09.2026; API-токен Timeweb,
новый хостинг и смена DNS для этого шага не нужны. Действующий сайт не менялся.
Юридические тексты остаются черновиками; §7.3 и процент готовности
350/488 = 71,7% не закрываются локальным preview.
