# Verified rental review policy MVP

Review — отдельный UGC-объект, подтверждённый завершённой арендой. Он не меняет
Booking, Payment/Payout/Dispute или evidence и не может быть создан редактором,
оператором либо импортом.

## Eligibility and content

- Только borrower и lender конкретной Booking со статусом `COMPLETED` могут
  оставить по одному отзыву друг о друге. Author и target всегда выводятся из
  Booking; client не передаёт их ID.
- Окно создания — 14 календарных суток от server timestamp перехода Booking в
  `COMPLETED`. Отсутствующая append-only transition history закрывает создание
  fail-closed.
- Rating — обязательное целое число `1..5`. Text опционален: после trim либо
  отсутствует, либо содержит 10–1000 символов без C0/DEL control characters.
- Один stable UUID v4 делает повтор того же payload идемпотентным. Вторая оценка
  той же стороны и reuse UUID с иным payload получают conflict.

## Double-blind publication

- До публикации автор видит только собственный submitted review; вторая сторона
  и public API не видят ни rating, ни text, ни факт конкретной оценки.
- Если обе стороны отправили reviews до deadline, оба публикуются атомарно в
  момент второго submit. Иначе единственный review публикуется по достижении
  `completedAt + 14 дней`. `publishAt` является server-derived временем, поэтому
  отдельный scheduler не нужен: public query допускает только `publishAt <= now`.
- Rating/text после create не редактируются и не удаляются пользователем. Это
  сохраняет double-blind и предотвращает изменение оценки после раскрытия.

## Public provenance and aggregate

- Public response сообщает только verified-rental provenance, безопасную роль
  автора, rating/text и timestamps. Booking ID, даты/цена аренды, user IDs,
  адрес, контакт и evidence не раскрываются.
- Rating/count считается только по `publishAt <= now` и не скрытым review.
  До первого опубликованного review UI показывает «Новый владелец»; тестовые,
  импортированные и редакторские оценки запрещены.
- Block не удаляет review и не меняет Booking. Он остаётся доступен для report,
  moderation, dispute evidence и retention; новых свободных контактов не создаёт.

## Moderation, appeal and retention

- Report target `REVIEW` использует общий rate/dedup и разрешён только для
  опубликованного review; собственный/скрытый/неопубликованный target недоступен.
- MODERATION может dismiss report либо скрыть review с обязательной причиной и
  append-only audit. Скрытие исключает review из public list/aggregate, но не
  меняет факт `COMPLETED`, деньги, спор или evidence. Автор получает нейтральное
  уведомление без личности reporter.
- Апелляция идёт через обычный support ticket; восстановление review — отдельное
  аудируемое решение, а не редактирование исходного rating/text.
- По принятой baseline ADR-0002 Review/report/moderation хранится 3 года после
  публикации либо закрытия связанной жалобы/апелляции — что позже; scoped legal
  hold имеет приоритет. После закрытия автора показывается анонимная provenance,
  а закрытый target не имеет публичного профиля/aggregate. До public release срок
  и формулировки повторно проверяет RF legal/privacy specialist.
