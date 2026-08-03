# ADR-0002: Жизненный цикл данных аккаунта

- Status: ACCEPTED
- Date: 2026-07-27
- Decision owner: Product owner
- Reviewers: Privacy/legal specialist — обязательно до public release
- Related checklist gate: 3 Users; 7.2 marketplace legal/safety
- Evidence: Product owner decision recorded in the project workspace on 2026-07-27; primary legal sources listed in `docs/data-retention-and-export.md`
- Supersedes / Superseded by: N/A

## Контекст

Закрытие аккаунта уже немедленно отзывает сессии и скрывает пользователя, но
продукту нужен единый контракт: что попадает в export, когда удаляются разные
категории данных и какие минимальные записи сохраняются для учета, спора и
аудита. Полное физическое удаление всей строки пользователя может разрушить
Booking, payout, reconciliation и доказательство действий администратора.

## Рассмотренные варианты

1. Удалять все данные сразу — просто, но разрушает активные обязательства и
   обязательный financial/audit trail.
2. Хранить весь аккаунт бессрочно — удобно операционно, но нарушает минимизацию и
   не дает проверяемого удаления.
3. Сразу скрывать аккаунт и отзывать сессии, затем удалять данные по категориям,
   сохраняя только минимальный pseudonymous след до истечения конкретного срока.

## Решение

Выбран вариант 3. Каноническая матрица категорий, экспорт, backup propagation и
правила legal hold описаны в
[`docs/data-retention-and-export.md`](../data-retention-and-export.md).

- Прямые идентификаторы удаляются не позднее 30 дней после исчезновения
  последнего законного blocker.
- Financial trail хранится не менее 5 лет после соответствующего отчетного года,
  без raw provider payload и лишних ПД.
- Booking/evidence/support/audit имеют отдельные сроки; закрытие аккаунта не
  каскадно удаляет связанные immutable записи.
- Export предоставляется в JSON/archive, исключает чужие данные и секреты и не
  отменяет обязательный срок хранения.
- Legal hold ограничивается делом и категориями, имеет владельца и дату
  пересмотра; бессрочный hold всего аккаунта запрещен.
- KYC этим ADR не разрешается: provider-managed/local ветка и ее retention
  остаются отдельным обязательным ADR.

## Последствия

- Retention jobs и export endpoint должны использовать одну versioned matrix.
- Связанные записи хранят pseudonymous subject ID; телефон, имя и точный адрес не
  копируются в financial/admin audit payload.
- Public privacy и account-deletion страницы должны объяснять категории,
  активные обязательства, сроки и канал запроса.
- Точные правовые основания и применимость сроков проверяются до public release;
  этот ADR не закрывает общий marketplace legal/safety gate.

## Rollout и rollback

Сначала реализуются export inventory и deletion jobs для существующих
PostgreSQL/Redis/S3 данных, затем processor deletion и backup restore drill.
Уменьшение срока выполняется очисткой просроченных данных; увеличение допустимо
только после legal/privacy review и обновления публичных документов. Откат к
бессрочному хранению запрещен.

## Checklist

- Разблокированные пункты: фиксация export/retention/delete по категориям в
  разделе 3; проектирование export endpoint и retention jobs.
- Пункты `[~]` N/A: отсутствуют.
- Обязательные тесты/gates: category inventory; idempotent deletion; export
  ownership/redaction; legal-hold scope; S3/Redis/processor cleanup; backup
  restore with tombstone replay.
- Дата следующего пересмотра: до публикации privacy/account-deletion pages и
  после выбора payment/KYC provider.

