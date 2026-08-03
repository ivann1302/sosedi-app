# UGC report contract

## Цель жалобы

Одна жалоба относится ровно к одной цели:

- `ITEM` — опубликованное объявление;
- `USER` — другой пользователь;
- `BOOKING` — бронирование, в котором reporter является borrower или lender.

Жалоба не является финансовым dispute и сама не меняет Item, User, Booking,
Payment или Payout.

## Reason codes

| Target | Допустимые reason codes |
|---|---|
| `ITEM` | `PROHIBITED_CATEGORY`, `MISLEADING_LISTING`, `UNSAFE_ITEM`, `SUSPECTED_FRAUD`, `OTHER` |
| `USER` | `HARASSMENT`, `IMPERSONATION`, `PRIVACY_VIOLATION`, `SUSPECTED_FRAUD`, `OTHER` |
| `BOOKING` | `NO_SHOW`, `UNSAFE_HANDOVER`, `ITEM_NOT_AS_DESCRIBED`, `HARASSMENT`, `SUSPECTED_FRAUD`, `OTHER` |

Backend проверяет сочетание target/reason и не принимает произвольную строку.

## Описание и evidence

- описание обязательно: от 20 до 1000 Unicode-символов;
- для `OTHER` описание должно содержать не менее 50 символов;
- допускается от 0 до 3 приватных изображений JPEG/PNG/WebP, каждое не более
  10 МБ;
- видео, аудио, архивы, исполняемые файлы и документы в MVP не принимаются;
- evidence проходит тот же quarantine, magic-bytes, size/MIME, SHA-256 и
  actor/entity binding, что Support attachment;
- постоянный storage URL не возвращается.

Личность reporter не раскрывается затронутой стороне. Жалоба создаёт очередь
ручной модерации и не приводит к автоматическому скрытию объявления или
блокировке пользователя.

## Уведомление после решения

Уведомление создаётся только после аудированного решения модератора и атомарно с
ним. При `HIDE_LISTING` владелец получает нейтральное
`ITEM_HIDDEN_BY_REPORT_REVIEW`, связанное только с его Item. Event и push payload
не содержат report ID, reporter ID, имя автора, reason или текст жалобы.

Для `DISMISS` уведомления затронутой стороне нет. При `BLOCK_USER` отдельное
уведомление не отправляется: заблокированный аккаунт уже теряет сессии, а
раскрытие момента расследования может быть небезопасно. Возврат этого канала
требует утверждённой policy и способа доставки без обхода блокировки.
