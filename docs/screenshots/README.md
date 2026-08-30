# Скриншоты клиентских маршрутов

Визуальная последовательность экранов собрана в
[`docs/app-user-paths.html`](../app-user-paths.html).

Снимки обновлены 30.08.2026 из реального Flutter UI на безопасных локальных
фикстурах. Все PNG имеют размер 430×932. Демо-карта использует только
приблизительные координаты каталога, а демо-оплата не списывает деньги и не
меняет серверное состояние бронирования. Эти две заглушки отключены в
production/release-конфигурации. Демо-карта сохраняет фильтры и выбранную вещь
при переходах список → карта → карточка → назад; тестовая оплата показывает
обработку и блокирует повторное нажатие до результата.

| Файл                     | Клиентский путь или состояние                       |
| ------------------------ | --------------------------------------------------- |
| `01-onboarding.png`      | `/onboarding`                                       |
| `02-phone-login.png`     | `/auth/phone`                                       |
| `03-otp.png`             | `/auth/otp`                                         |
| `04-catalog.png`         | `/catalog`, список                                  |
| `05-map-demo.png`        | `/catalog`, локальная демо-карта                    |
| `06-item-details.png`    | `/items/item-1`                                     |
| `07-booking-create.png`  | `/items/item-1/booking`                             |
| `08-bookings.png`        | `/bookings`                                         |
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
