# ADR-0005: Монетизированная безопасная сделка

- Status: PROPOSED
- Date: 2026-08-09
- Updated: 2026-09-14
- Decision owner: Кукуй Олег Игоревич, владелец продукта
- Contracting entity head: Кукуй Олег Игоревич; наименование и реквизиты юрлица
  ещё не зафиксированы
- Reviewers: payment provider, legal, accounting/tax
- Related checklist gate: раздел 14 Payments
- Evidence: [`docs/payment-provider-comparison.md`](../payment-provider-comparison.md)
- Supersedes / Superseded by: N/A

## Контекст

«Всё рядом» должен получать вознаграждение с завершённой P2P-аренды. Деньги
арендатора должны быть защищены до возврата вещи, а стоимость аренды должна
выплачиваться частному владельцу без промежуточного зачисления всей суммы на
расчётный счёт «Всё рядом».

Этот ADR покрывает только внешние P2P-объявления. Платёжный/фискальный сценарий
имущества ИП/ООО «Всё рядом» относится к PROPOSED ADR-0006 и не включается неявно.

Обычный checkout + webhook не решает hold, refund и выплату частному владельцу.
Ручная выплата со счёта «Всё рядом» не допускается.

## Рассмотренные варианты

1. CloudPayments «Безопасная сделка» — публично описаны расчёты между физлицами,
   заморозка до двух месяцев, комиссия площадки, два терминала оплаты/выплат,
   схемы `NToOne`/`OneToN`, API, HMAC-уведомления и status lookup. Тариф,
   поддерживающий банк-эквайер, применимость к аренде, onboarding и финансовая
   ответственность требуют индивидуального договора.
2. ЮKassa «Безопасная сделка» — публично документированный hold до 180 дней,
   выплаты физлицам и отдельное вознаграждение площадки; тариф и подключение
   требуют индивидуального договора.
3. Т‑Банк «Мультирасчёты» — hold, split и выплаты физлицам/юрлицам; тариф
   индивидуальный, срок сделки короче, подключение может занять до 60 дней.
4. `PAY_ON_HANDOVER` — технически доступный zero-commission fallback, но не
   реализует выбранную владельцем монетизацию.

## Предлагаемое решение

- Целевой release-сценарий — `SAFE_DEAL`.
- Основной кандидат по решению владельца продукта — CloudPayments, только после
  письменного подтверждения платной P2P-аренды личных вещей, допустимого
  стартового оборота, банка-эквайера, двух связанных терминалов, тарифа и
  договора.
- Первый fallback — ЮKassa «Безопасная сделка», второй — Т‑Банк
  «Мультирасчёты»; production adapter реализуется только для одного провайдера.
- CloudPayments управляет расчётами до решения площадки, после чего выплачивает
  владельцу утверждённую сумму и позволяет площадке получить согласованное
  вознаграждение. Точное движение денег и ответственность фиксирует договор.
- «Всё рядом» не принимает и не хранит PAN/CVC и не получает на свой счёт всю сумму
  аренды.
- Вознаграждение «Всё рядом» признаётся после успешной выплаты владельцу, чтобы
  полный возврат не требовал возвращать уже полученную комиссию площадки.
- Продуктовая цель монетизированного пилота — platform fee 1% от стоимости
  аренды. Кто его платит, как показывается gross price и как покрывается provider
  cost, пока не решено.
- Fake-provider пока технически использует 1% без fixed/min/max из выплаты
  владельцу, без наценки арендатору; округление до ближайшей копейки, ровно
  половина — вверх. Это placeholder для unit-тестов, а не production fee-payer
  decision.
- 1% не является разрешением публиковать тариф или экономически самодостаточной
  моделью. До `ACCEPTED` нужно выбрать owner deduction, renter fee/наценку,
  отдельное раскрытие provider cost или ограниченную subsidy; для subsidy заранее
  утверждаются бюджет/cap и disclosure.
- После пилота продуктовая цель — 5% маржи «Всё рядом» по отдельно утверждённой
  формуле. Её база, состав учитываемых provider/fiscal/refund costs и будущий
  displayed fee остаются `TBD`; «маржа 5%» нельзя молча заменить «комиссией 5%».
- Тариф хранится как `commissionBps + pricingPolicyVersion + effectiveAt` и
  snapshot конкретной Booking; новая политика не пересчитывает старые сделки.
- После подтверждения владельцем арендатору предлагается 30 минут на Safe Deal
  оплату через согласованный Widget/mobile SDK/3-D Secure flow. `payBy`, provider
  expiry/cancel и обработка позднего webhook требуют проверки на выданных
  CloudPayments test terminals и не применяются к `PAY_ON_HANDOVER`.
- Fixed/min/max, касса, provider cost, refund rules и KYC остаются `TBD` до
  коммерческого предложения и legal/accounting review.
- Выбор `NToOne` либо `OneToN`, правила `FinalPayout` и место platform fee в
  денежных потоках не выводятся из публичного примера и остаются частью gate.

Это `PROPOSED`, а не разрешение включать production payments.

## Последствия

- Черновые legal-страницы могут описывать целевую модель без обещания процента и
  без включения checkout.
- Репозиторий содержит gated `FAKE_SAFE_DEAL` test slice: schema и миграции,
  exact-minor Booking snapshot/checkout/deposit/dispute operations, race и auth
  tests, безопасную operator queue и server-backed mobile UX. Режим требует
  явной non-production конфигурации и запрещён release-gate в production.
- Fake provider исполняет только тестовые hold/refund/release outcomes; live
  provider adapter, Widget/SDK/API/webhook flow, payout, чеки и reconciliation
  не реализованы.
- Будущая CloudPayments migration заменяет legacy `yookassaPaymentId` на
  provider-neutral transaction/deal IDs и сохраняет `TransactionId` плюс
  `EscrowAccumulationId`; текущая provisional schema сейчас не меняется.
- Этот test slice не выбирает release-provider, fee payer, production dispute
  window или KYC-ветку, не закрывает ни один provider/legal/accounting gate и не
  меняет статус ADR `PROPOSED`.
- После предложения провайдера нужно утвердить price formula/fee payer/provider-
  cost coverage, KYC-ветку, cancellation/dispute/payment-timeout matrix, чеки и
  reconciliation.

## Rollout и rollback

До `ACCEPTED` ADR и provider contract payment mode остаётся disabled. Тесты
используют fake provider. Если CloudPayments откажет, не подтвердит P2P-аренду
или предложит неподходящие условия, ADR пересматривается сначала для ЮKassa,
затем для Т‑Банка без параллельной реализации production adapter.

## Checklist

- Разблокированные пункты: нет до статуса `ACCEPTED`.
- Пункты `[~]` N/A: нет.
- Обязательные tests/gates: разделы 13.1, 14 и 15 `MVP_CHECKLIST.md`.
- Дата следующего пересмотра: после письменного предложения CloudPayments,
  выдачи test terminals и legal/accounting review.
