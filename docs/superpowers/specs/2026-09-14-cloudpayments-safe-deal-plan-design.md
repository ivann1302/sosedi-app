# CloudPayments Safe Deal plan update design

Дата: 14.09.2026

Статус: одобрено владельцем продукта для обновления плана; production-платежи
остаются заблокированы до provider/legal/accounting gate.

## Цель

Сделать CloudPayments «Безопасная сделка» основным кандидатом для
монетизированной P2P-аренды Sosedi и привести исполняемый roadmap и связанные
документы к актуальному продукту и API провайдера. Это документационная задача:
она не подключает боевые платежи, не меняет БД или приложение и не закрывает
чекбоксы provider gate.

`MVP_CHECKLIST.md` остаётся единственным исполняемым источником scope, порядка,
статусов и процента готовности. Эта спецификация фиксирует только согласованный
дизайн обновления.

## Решение

- Целевой online-сценарий — CloudPayments «Безопасная сделка» для расчётов между
  физическими лицами.
- ADR-0005 остаётся `PROPOSED`, пока CloudPayments письменно не подтвердит
  применимость к платной аренде личных вещей, договор, тариф, банк-эквайер,
  onboarding получателей, выплаты, возвраты, фискализацию и ответственность
  площадки.
- `PAY_ON_HANDOVER` остаётся разрешённым fallback пилота с комиссией Sosedi 0%.
- `FAKE_SAFE_DEAL` остаётся единственным online-сценарием для локальных и
  staging-тестов до прохождения gate.
- Один production-провайдер реализуется после gate. Параллельные adapter для
  CloudPayments, ЮKassa и Т-Банка не создаются.

## Подтверждённые ограничения CloudPayments

Публичные официальные материалы подтверждают P2P Safe Deal, заморозку средств
до двух месяцев и возможность комиссии площадки. Техническая документация
указывает отдельные терминалы оплаты и выплат, поддержку только карт и токенов
карт, зависимость доступности от банка-эквайера, схемы `NToOne`/`OneToN`,
`EscrowAccumulationId`, `TransactionId`, Basic Auth, `X-Request-ID`, HMAC
уведомлений и запрос состояния сделки по `AccumulationId`.

Источники:

- <https://cloudpayments.ru/features/safe-deal>
- <https://developers.cloudpayments.ru/>

Публичная документация не заменяет договор. В частности, выбранная escrow-схема,
тариф, расчёт комиссии Sosedi, сроки хранения денег, правила частичных возвратов,
финальная выплата, чеки и ответственность при споре должны быть подтверждены
письменно.

## Изменения плана

### Provider gate

В разделе 14 `MVP_CHECKLIST.md` CloudPayments заменяет ЮKassa как основной
кандидат. Gate дополнительно требует:

- подтвердить, что платная аренда разрешённых личных вещей входит в договорный
  P2P-сценарий;
- получить два связанных терминала и подтвердить поддерживающий банк-эквайер;
- согласовать двухмесячный лимит со сроком advance booking, аренды, возврата и
  dispute window;
- утвердить допустимые карты/токены, onboarding и идентификацию владельца;
- зафиксировать роль Sosedi как арбитра и связанную финансовую ответственность;
- выбрать `NToOne` либо `OneToN` только после письменного подтверждения денежного
  потока, platform fee и финального закрытия сделки;
- согласовать тариф, fee payer, чеки, refund/payout costs и reconciliation.

### Будущая production-интеграция

После gate checklist должен требовать:

- CloudPayments Widget/мобильный SDK либо иной письменно одобренный flow с 3-D
  Secure; backend Sosedi не принимает и не хранит PAN/CVC;
- отдельные test/live credentials терминалов оплаты и выплат;
- provider-neutral локальную модель с `providerTransactionId` и
  `providerDealId`, где для CloudPayments deal ID — `EscrowAccumulationId`;
- migration legacy-поля `yookassaPaymentId` без потери существующих тестовых
  записей;
- локальные idempotency keys без опоры только на часовое окно `X-Request-ID`;
- проверку `X-Content-HMAC`/`Content-HMAC` по raw request bytes, сверку terminal,
  transaction/deal ID, суммы, RUB и test/live mode;
- идемпотентную монотонную обработку `Check`, `Pay`, `Fail`, `Confirm`, `Cancel`
  и `Refund` уведомлений в объёме утверждённого контракта;
- payout/refund через подтверждённые Safe Deal методы и запрет выплаты до
  завершения возврата и dispute window;
- ежедневную reconciliation по `AccumulationId`, локальным операциям и реестру
  провайдера.

Точный API payload и перечень callbacks фиксируются contract-тестами только
после выдачи тестовых терминалов и подтверждения менеджером CloudPayments.

## Документы для синхронизации

- `MVP_CHECKLIST.md` — provider gate, порядок и будущие задачи интеграции;
- `docs/adr/0005-monetized-safe-deal-provider.md` и `docs/adr/README.md`;
- `docs/payment-provider-comparison.md`;
- `sosedi-roadmap.html` — только визуальное отражение checklist;
- `AGENTS.md` — operational-инструкции, не меняющие roadmap;
- `docs/database-schema.md`, `docs/production-operations-runbook.md` и
  `docs/production-secrets-runbook.md` — удалить активные YooKassa-specific
  допущения и отразить будущую нейтральную migration.

Исторические evidence и завершённые task-планы не переписываются, если ссылка на
ЮKassa описывает прежний scope на дату выполнения. Активные документы не должны
утверждать, что CloudPayments уже подключён или что ADR принят.

## Проверка документационной задачи

- статусы чекбоксов и процент готовности не изменились;
- `MVP_CHECKLIST.md`, roadmap HTML и operational-инструкции не противоречат друг
  другу;
- активные provider-specific требования называют CloudPayments;
- stale scan не находит активных требований реализовать ЮKassa;
- `git diff --check` проходит;
- никакие исходники, schema/migration, env или secrets не изменены.
