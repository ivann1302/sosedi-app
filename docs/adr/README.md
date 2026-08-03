# Architecture Decision Records

ADR хранит только принятое business, legal, provider или архитектурное решение.
Исполняемые задачи, порядок, Definition of Done и прогресс остаются в
[`MVP_CHECKLIST.md`](../../MVP_CHECKLIST.md).

## Реестр

| ADR | Status | Решение |
| --- | --- | --- |
| [0001](0001-paid-neighbor-item-rental.md) | ACCEPTED | Платная P2P-аренда разрешённых вещей между соседями; domain migration от tool prototype обязательна до следующей продуктовой функции. |
| [0002](0002-account-data-lifecycle.md) | ACCEPTED | Категорийные сроки export/delete, scoped legal hold и сохранение минимального financial/audit trail. |
| [0003](0003-launch-category-safety-policy.md) | ACCEPTED | Deny-by-default launch whitelist, запрещённые/ограниченные категории и обязательные safety-предупреждения. |
| [0004](0004-delivery-out-of-mvp-1.md) | ACCEPTED | Delivery entry point и передача адреса внешнему приложению исключены из MVP 1.0; личный handover независим. |

## Статусы

- `PROPOSED` — решение обсуждается и не разблокирует зависимые функции.
- `ACCEPTED` — решение принято указанным владельцем и может разблокировать gate.
- `REJECTED` — вариант отклонён.
- `SUPERSEDED` — заменён новым ADR; старый файл не удаляется.

Пункт checklist можно отметить `[~]` (N/A) только когда `ACCEPTED` ADR выбрал
взаимоисключающую ветку и явно перечислил исключённые пункты.

## Именование

Использовать `NNNN-short-title.md`, например:

```text
0001-payment-release-scenario.md
0002-kyc-identification-branch.md
```

## Шаблон

```markdown
# ADR-NNNN: Короткое название

- Status: PROPOSED | ACCEPTED | REJECTED | SUPERSEDED
- Date: YYYY-MM-DD
- Decision owner: роль или ответственное лицо
- Reviewers: роли/специалисты
- Related checklist gate: раздел и пункт
- Evidence: ссылка на договор/письмо/документацию без секретов и ПД
- Supersedes / Superseded by: ADR-NNNN или N/A

## Контекст

Какое решение требуется, какие ограничения и риски существуют.

## Рассмотренные варианты

1. Вариант A — преимущества и риски.
2. Вариант B — преимущества и риски.

## Решение

Выбранный вариант, точные границы и запрещённые допущения.

## Последствия

Что меняется в продукте, данных, API, тестах, эксплуатации и документах.

## Rollout и rollback

Как включить, проверить, выключить или заменить решение.

## Checklist

- Разблокированные пункты:
- Пункты `[~]` N/A:
- Обязательные тесты/gates:
- Дата следующего пересмотра:
```

## Обязательные ADR до production

- release-сценарий платежей и комиссия: Safe Deal либо offline pilot 0%;
- идентификация владельца: provider-managed либо local KYC;
- marketplace legal/safety rules и prohibited categories;
- включение или исключение delivery handoff;
- retention/legal hold для аккаунтов, evidence и KYC.

Не хранить в ADR токены, реквизиты, паспортные данные, закрытые договоры или
персональную переписку. Для них указывать только контролируемую внешнюю ссылку.
