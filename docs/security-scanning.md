# Dependency and secret scanning

`make security-scan` проверяет:

- `backend/package-lock.json`, `operator/package-lock.json`,
  `public-web/package-lock.json` и `mobile/pubspec.lock` по локальной OSV
  database;
- Git history через Gitleaks;
- tracked и ещё не закоммиченные файлы через Gitleaks directory scan.

OSV-Scanner 2.5.1 запускается с
`--offline --offline-vulnerabilities --no-resolve`: состав зависимостей и
исходный код не отправляются внешним сервисам. Явные lockfile обязательны:
recursive `.` в этой версии и окружении не извлекает package sources. Перед
запуском нужно отдельно установить `osv-scanner` и `gitleaks`, затем обновить
локальную публичную OSV database:

```bash
osv-scanner scan source \
  --lockfile=backend/package-lock.json \
  --lockfile=operator/package-lock.json \
  --lockfile=public-web/package-lock.json \
  --lockfile=mobile/pubspec.lock \
  --offline-vulnerabilities \
  --download-offline-databases \
  --no-resolve \
  --config=backend/osv-scanner.toml
```

На macOS osv-scalibr хранит загруженные архивы в
`~/Library/Caches/osv-scalibr/npm/all.zip` и
`~/Library/Caches/osv-scalibr/Pub/all.zip`. Команда выше обновляет оба cache;
`make security-scan` после этого использует их без сети.

Generated dependencies, build output и отдельные checkout внутри `.worktrees/`
исключены из directory scan в `.gitleaks.toml`; каждый worktree проверяется из
собственного корня, а Git history всё равно сканируется полностью. Узкий
allowlist совмещает rule, точный путь и точное значение публичного RFC 6238 test
vector; другие значения или файлы он не пропускает. Один fingerprint в
`.gitleaksignore` относится к удалённому из текущего дерева демонстрационному
CircleCI token из стандартного Nest README. Это не действующий credential.

## Baseline 04.09.2026

Сканирование выполнено OSV-Scanner `2.5.1` с osv-scalibr local database и
Gitleaks `8.30.1`.

Первичный OSV scan четырёх lockfile обнаружил 26 fixable advisories в
`brace-expansion`, `browserslist`, `fast-uri`, `js-yaml`, `qs`, `deepmerge-ts`
и `nanoid`. Совместимые transitive версии обновлены. `prisma@6.19.3` через
`@prisma/config@6.19.3` фиксирует уязвимый `deepmerge-ts@7.1.5`, поэтому в
корневом `backend/package.json` добавлен точечный override `deepmerge-ts ^8.0.0`.
Он допустим для единственного config merge callsite, описанного в Prisma issue
`#30052`, и должен быть удалён после перехода Prisma на исправленную зависимость.

Истёкший ignore `GHSA-mh99-v99m-4gvg` удалён: patched версии доступны и
установлены, активных OSV ignores нет.

Итог:

- OSV: четыре lockfile извлечены, непокрытых vulnerabilities нет;
- `npm ls` подтверждает исправленные transitive версии и `deepmerge-ts`
  override;
- Gitleaks Git history: leaks не найдены;
- Gitleaks working directory: leaks не найдены.

При новой находке dependency обновляется до исправленной версии. Исключение или
risk acceptance добавляется только с advisory ID, причиной, владельцем и датой
пересмотра; секреты по baseline не принимаются.
