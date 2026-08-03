# Dependency and secret scanning

`make security-scan` проверяет:

- `backend/package-lock.json` и `mobile/pubspec.lock` по локальной OSV database;
- Git history через Gitleaks;
- tracked и ещё не закоммиченные файлы через Gitleaks directory scan.

OSV запускается с `--offline --offline-vulnerabilities --no-resolve`: состав
зависимостей и исходный код не отправляются внешним сервисам. Перед запуском
нужно отдельно установить `osv-scanner` и `gitleaks`, затем обновить локальную
публичную OSV database:

```bash
osv-scanner scan source \
  --recursive \
  --offline \
  --offline-vulnerabilities \
  --download-offline-databases \
  --no-resolve \
  --config=backend/osv-scanner.toml \
  .
```

Generated dependencies и build output исключены из directory scan в
`.gitleaks.toml`; Git history всё равно проверяется полностью. Один fingerprint
в `.gitleaksignore` относится к удалённому из текущего дерева демонстрационному
CircleCI token из стандартного Nest README. Это не действующий credential.

## Baseline 27.07.2026

Сканирование выполнено OSV-Scanner `2.4.0` и Gitleaks `8.30.1`. Бинарные файлы
были скачаны из официальных GitHub Releases и проверены по SHA-256.

Первичный OSV scan обнаружил high advisories в npm dependency tree:
`brace-expansion`, `fast-uri`, `form-data`, `js-yaml`, `multer` и `sharp`.
Зависимости обновлены до исправленных версий; для `js-yaml` добавлен точечный
npm override, потому что непосредственный потребитель ещё фиксировал уязвимую
версию.

Для `GHSA-mh99-v99m-4gvg` оформлено временное risk acceptance до `31.08.2026`.
Оставшиеся `brace-expansion` 1.x/2.x приходят только через devDependencies
ESLint/Jest, не получают пользовательские данные и не входят в production
backend. Принудительный переход на 5.0.8 несовместим со старым API `minimatch` и
ломает lint. Владелец риска — разработчик; пересмотр обязателен при обновлении
upstream-зависимостей или не позднее даты истечения.

Итог:

- OSV: новых непокрытых vulnerabilities в npm/Dart lockfiles нет;
- OSV + `npm ls`: production high/critical нет; один dev-only advisory принят
  временно, а npm audit считает его по каждому dependency path;
- Gitleaks Git history: leaks не найдены;
- Gitleaks working directory: leaks не найдены.

При новой находке dependency обновляется до исправленной версии. Исключение или
risk acceptance добавляется только с advisory ID, причиной, владельцем и датой
пересмотра; секреты по baseline не принимаются.
