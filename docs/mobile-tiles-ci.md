# Tiles key: сборка и CI

## Готовая автономная часть — 09.09.2026

`scripts/build-mobile-release.mjs` получает `YANDEX_TILES_API_KEY` из окружения
для AAB/IPA. Раньше release wrapper пропускал его, поэтому карта скрывалась.
Теперь ключ попадает в приватный JSON-файл в системной временной папке:
папка недоступна группе/остальным пользователям, файл имеет права `600`.
В аргументах Flutter передаётся только путь `--dart-define-from-file`.
`finally` удаляет папку после успеха или ошибки; release manifest не содержит ключ.

Отсутствующий ключ по-прежнему допустим в release wrapper: приложение сохраняет
ручной ввод адреса и скрывает карту. Проверки production environment, approved
documents, signing и clean Git HEAD не ослаблены.

Ключ клиентского Tiles API можно извлечь из готового приложения. CI secrets и
приватный временный файл защищают исходники/обычные аргументы сборки, но не
заменяют доступные ограничения ключа, лимиты и мониторинг использования в Яндексе.
Не публиковать verbose build logs или промежуточные Flutter/Gradle artifacts:
они могут содержать compile-time defines, в том числе в кодированном виде.

## Ручная CI-проверка

Workflow `.github/workflows/mobile-tiles-smoke.yml` запускается только вручную
с default branch. Он использует environment `mobile-map-smoke`, получает ключ
только на шаге сборки, собирает debug APK и не выгружает артефакт. В конце
удаляется `mobile/build`; временный GitHub runner далее уничтожается.

Чтобы закрыть внешнюю часть пункта §9:

1. После ревью разместить workflow и build scripts в default branch.
2. Создать environment `mobile-map-smoke`, ограничить его default branch и
   настроить required reviewers, если это доступно для текущего репозитория.
3. Добавить environment secret `YANDEX_TILES_API_KEY`. Не копировать значение
   в исходники, issue, сообщения или команды shell с литералом реального ключа.
4. Запустить `Mobile Tiles smoke` вручную и сохранить URL успешного run.
   Если ключ отсутствует, build завершается ошибкой, а не успешной сборкой без карты.

Hosted проверка выполнена 09.09.2026: environment `mobile-map-smoke`
ограничен веткой `main`, владелец добавил `YANDEX_TILES_API_KEY`.
[Run 34342751765](https://github.com/ivann1302/sosedi-app/actions/runs/34342751765)
на коммите `1322e4bfd77eb03805e5ed1961eebf1c8ebdc4d9` завершился успешно:
проверки helpers, сборка debug APK и очистка build artifacts прошли.
Это подтверждает сборку с CI secret, но не HTTP-запрос к Яндексу из этой APK.
Ограничения ключа в кабинете Яндекса ещё не настроены/не подтверждены.
Local fixture build не подтверждает production privacy/store/provider gates.

## Локальная проверка

Из корня репозитория, без настоящего ключа:

```sh
make mobile-release-config-test
YANDEX_TILES_API_KEY=ci-build-only-fixture make mobile-tiles-smoke
```

Результат 09.09.2026: 18 проверок release config/build/artifact passed; ESLint
для изменённых JS passed; YAML разобран и проверены manual/default-branch,
environment/secret-step и отсутствие artifact upload. Реальная debug APK собрана
из locked dependencies; внутри Flutter kernel найдено ожидаемое тестовое
значение, временных key directories после сборки не осталось. Это проверяет
передачу ключа в компилятор, а не HTTP-запрос к Яндексу. На устройство APK не
устанавливалась. Независимое ревью существенных замечаний не нашло.

Dart-код не менялся: Flutter analyzer и полный mobile unit suite повторно не
запускались; изменение проверено JS-тестами, линтером и настоящей APK-сборкой.
Существующее предупреждение Flutter о будущей несовместимости KGP-плагинов
сборке не помешало; зависимости в этой задаче не обновлялись.

## Ограничение домена — подготовка 09.09.2026

Оба native Flutter слоя Tiles отправляют `Referer: https://sosedi-app.ru/`.
Один реальный запрос с этим заголовком вернул HTTP 200 image/png.
В кабинете Яндекса для существующего Tiles key нужно разрешить домен
`sosedi-app.ru` (без протокола/пути); IP-список не заполнять для мобильных клиентов.
Сначала установить обновлённое приложение: прежняя сборка не отправляет Referer.
По [документации](https://yandex.ru/maps-api/docs/tiles-api/limit.html)
изменение вступает в силу через 15 минут; затем проверить каталог и picker
на устройстве. Настройки кабинета и device smoke ещё не выполнены, §9 открыт.
Доменный Referer извлекается/подделывается клиентом и не является защитой
на уровне подписи приложения. Документация также оговаривает ограничения
только для тарифицируемых запросов: фактическое отклонение чужого Referer
нужно проверить, не обещая защиту бесплатных тайлов заранее.

Проверки подготовки: regression-тест упал без Referer и прошёл после правки;
`make mobile-analyze`, все 321 mobile tests и `make mobile-tiles-smoke` прошли.
Локальный APK: `mobile/build/app/outputs/flutter-apk/app-debug.apk`;
он содержит клиентский ключ и не добавляется в Git/публичные artifacts.
