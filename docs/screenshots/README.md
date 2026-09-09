# Скриншоты клиентских маршрутов

Визуальная последовательность экранов собрана в
[`docs/app-user-paths.html`](../app-user-paths.html).

Снимки обновлены из реального Flutter UI на безопасных локальных фикстурах.
Карта каталога отдельно фиксируется на физическом Android с Yandex Tiles API.
Набор использует встроенный Onest Variable 2.001 и утверждённую
плоскую marketplace-иерархию: каталог в две колонки, линейные детали и
сгруппированные строки без декоративных card stacks. Все PNG имеют размер
430×932. Каталог показывает сгенерированные pilot-обложки. Карта использует
только приблизительные координаты, группирует близкие маркеры и показывает
фото-карточку после выбора; фильтры и выбранная вещь сохраняются при переходах
список → карта → карточка → назад.
Демо-оплата не списывает деньги, не меняет серверное состояние бронирования,
показывает обработку и блокирует повторное нажатие до результата.

| Файл                     | Клиентский путь или состояние                       |
| ------------------------ | --------------------------------------------------- |
| `01-onboarding.png`      | `/onboarding`, польза аренды                        |
| `01b-onboarding-trust.png` | `/onboarding`, доверие и правила                  |
| `01c-onboarding-search.png` | `/onboarding`, переход к поиску                   |
| `02-phone-login.png`     | `/auth/phone`                                       |
| `03-otp.png`             | `/auth/otp`                                         |
| `04-catalog.png`         | `/catalog`, список                                  |
| `05-map.png`             | `/catalog`, Yandex Tiles, кластеры и карточка вещи  |
| `06-item-details.png`    | `/items/item-1`                                     |
| `07-booking-create.png`  | `/items/item-1/booking`                             |
| `08-bookings.png`        | `/bookings`                                         |
| `08a-booking-pending-borrower.png` | `/bookings/booking-pending`, ожидает владелец |
| `08b-booking-pending-lender.png` | `/bookings/booking-pending-lender`, решение владельца |
| `09a-booking-confirmed.png` | `/bookings/booking-confirmed`, подтверждено       |
| `09b-booking-active.png` | `/bookings/booking-active`, вещь в аренде           |
| `09c-booking-returned.png` | `/bookings/booking-returned`, возврат             |
| `09d-booking-completed.png` | `/bookings/booking-completed`, завершено          |
| `09e-booking-cancelled.png` | `/bookings/booking-cancelled`, отменено           |
| `09-payment-demo.png`    | `/bookings/booking-confirmed`, успешная демо-оплата |
| `10-booking-chat.png`    | `/bookings/booking-confirmed/chat`                  |
| `11-create-item.png`     | `/items/new`                                        |
| `12-owned-items.png`     | `/items/mine`                                       |
| `13-inbox.png`           | `/inbox`                                            |
| `14-profile.png`         | `/profile`                                          |
| `15-support.png`         | `/support`                                          |
| `16-review.png`          | `/bookings/booking-completed/review`                |
| `17-item-edit.png`       | `/items/item-1/edit`                                |
| `18-owner-profile.png`   | `/items/item-1/owner`                               |
| `19-profile-edit.png`    | `/profile/edit`                                     |
| `20-sessions.png`        | `/profile/sessions`                                 |
| `21-analytics.png`       | `/profile/analytics`                                |
| `22-documents.png`       | `/profile/documents`                                |
| `23-data-export.png`     | `/profile/data-export`                              |
| `24-close-account.png`   | `/profile/close-account`                            |
| `25-blocked-users.png`   | `/profile/blocked-users`                            |
| `26-support-export.png`  | `/support/export`                                   |
| `27-support-ticket.png`  | `/support/ticket-1`                                 |
| `28-update-required.png` | `/update-required`                                  |
| `29-favorites.png`       | `/profile/favorites`                                |

`/home` — redirect на `/catalog`; `/` — краткий служебный splash, поэтому для
них отдельные продуктовые снимки не создаются.

Перегенерация из корня проекта:

```sh
make mobile-screenshots
```

Генератор: `mobile/tool/capture_client_screenshots_test.dart`.
