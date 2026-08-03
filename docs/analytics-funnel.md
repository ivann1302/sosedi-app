# Privacy-safe MVP analytics funnel

AppMetrica по умолчанию не подключена и не может быть включена одним
`dart-define`. `DisabledAnalyticsTransport.isConfigured == false`, поэтому
согласие нельзя выдать до отдельного privacy/legal review и реализации
проверенного adapter.

Разрешён только фиксированный funnel schema v1:

| Event | Момент |
| --- | --- |
| `app_opened` | запуск UI |
| `onboarding_completed` | завершён onboarding |
| `otp_requested` | SMS request принят backend |
| `login_completed` | OTP подтверждён |
| `catalog_opened` | пользователь открыл каталог |
| `booking_started` | пользователь перешёл к выбору дат |
| `listing_started` | пользователь открыл lender-сценарий |
| `listing_created` | backend создал объявление |

Payload содержит ровно `event` и `schema_version=1`. Параметры, phone, exact
address/coordinates, user/device/booking/item ID, поисковый текст, KYC,
payment, listing/booking content и произвольные properties API отсутствуют.

Consent хранится локально как `unknown/granted/denied`, по умолчанию `unknown`.
До `granted` события отбрасываются. При opt-out collection выключается,
локальный transport state очищается, новые события не отправляются. Экран:
`Профиль → Аналитика и согласие`.

Перед AppMetrica adapter обязательны:

1. опубликованная versioned privacy/consent страница и legal basis;
2. backend evidence принятой/отозванной версии consent;
3. RF/data-flow review AppMetrica и отключение advertising identifiers;
4. adapter test, перехватывающий фактический SDK payload;
5. device smoke grant → event → opt-out → отсутствие следующего event;
6. documented 12-month event retention и deletion/linkage procedure.

Unit-тест текущей границы перехватывает точный payload у transport и проверяет
отсутствие событий до consent и после opt-out. Это не разрешает активировать
AppMetrica до прохождения перечисленного gate.
