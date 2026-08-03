# ADR-0004: Delivery handoff вне MVP 1.0

- Status: ACCEPTED
- Date: 2026-07-29
- Decision owner: Product owner
- Reviewers: privacy/legal и mobile owner — до повторного включения
- Related checklist gate: 17.2 Delivery handoff
- Evidence: личная передача зафиксирована как единственный MVP-flow в `README.md`; delivery обозначена необязательным срезом в `MVP_CHECKLIST.md`
- Supersedes / Superseded by: N/A

## Контекст

Основной сценарий MVP заканчивается личной передачей вещи участниками
подтверждённой брони. Deep link в Яндекс Go не синхронизирует доставку с
бронированием, но добавляет отдельный privacy-flow: точные pickup/dropoff адреса
передаются внешнему приложению. Проверка спроса не зависит от этого сценария.

## Рассмотренные варианты

1. Добавить backend/API-интеграцию доставки — лишний provider contract и новая
   state machine вне MVP.
2. Добавить только client-side deep link с consent и fallback — технически
   проще, но всё равно требует отдельного privacy/store release gate.
3. Не включать delivery entry point в MVP 1.0 и оставить личную передачу
   независимой — минимальный продуктовый и privacy-риск.

## Решение

Выбран вариант 3. В MVP 1.0:

- delivery entry point и deep link в Яндекс Go отсутствуют;
- mobile и backend не передают точный адрес внешнему delivery-сервису;
- подтверждение личной выдачи/возврата и доступ участников к handover-данным не
  зависят от наличия Яндекс Go или системной карты;
- отсутствие delivery не блокирует публикацию, бронирование и handover.

Повторное включение требует нового `ACCEPTED` ADR с release scope, allowlisted
scheme/host, object-level authorization, явным consent, encoding/fallback,
privacy retention и тестами.

## Последствия

- Не добавляются delivery provider, статусы, API endpoint или analytics event.
- В интерфейсе нет скрытой или неработающей кнопки доставки.
- Точный адрес остаётся только в существующем participant handover contract.
- Шесть взаимоисключающих implementation/test пунктов 17.2 становятся `[~]` N/A.

## Rollout и rollback

Текущий код уже не содержит delivery entry point, поэтому rollout
документационный. «Rollback» выполняется только новым ADR и отдельной задачей,
которая возвращает исключённые пункты в исполняемый checklist.

## Checklist

- Разблокированный пункт: решение release scope в 17.2.
- Пункты `[~]` N/A: authorization/URL, consent, encoding, fallback, retention и
  delivery-specific tests в 17.2.
- Дата следующего пересмотра: после первых подтверждённых аренд, не раньше MVP
  1.0.
