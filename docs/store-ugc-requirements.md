# Store UGC requirements

Официальные требования проверены: 29.07.2026. Product scope обновлён:
09.08.2026. Использованы только официальные страницы магазинов.
Перед отправкой production-сборки требования нужно проверить повторно.

## Apple App Store

[App Review Guideline 1.2](https://developer.apple.com/app-store/review/guidelines/#user-generated-content)
требует:

- фильтрацию нежелательного UGC;
- встроенный механизм жалобы и своевременную реакцию;
- возможность блокировать abusive users;
- опубликованный контакт поддержки.

## Google Play

[User-generated content policy](https://support.google.com/googleplay/android-developer/answer/9876937)
и официальное
[пояснение по moderation](https://support.google.com/googleplay/android-developer/answer/12923286)
требуют:

- Terms of Use/user policy с определением запрещённого контента и обязательным
  принятием до создания UGC;
- постоянную соразмерную модерацию;
- отдельные, явно обозначенные in-app действия для report content/users и block
  users;
- своевременное действие по подтверждённым жалобам.

## RuStore

[Требования к приложениям RuStore](https://www.rustore.ru/help/developers/publishing-and-verifying-apps/requirement-apps)
требуют:

- своевременную адекватную премодерацию либо постмодерацию по жалобам;
- определение и критерии неприемлемого контента;
- механизм жалобы на оскорбительный контент;
- ограничение доступа для нарушителей;
- контакт поддержки/moderation team и своевременную реакцию.

## Состояние «Всё рядом»

Backend уже имеет target-specific report, user block, rate/dedup, operator
`dismiss / hide listing / block user`, capability/CSRF и audit. Item проходит
премодерацию, изменение фото возвращает его на модерацию.

Mobile уже даёт пожаловаться на listing/owner/booking, конкретное booking-chat
сообщение и опубликованный отзыв, явно заблокировать пользователя и управлять
blocked list. Backend
принимает `MESSAGE` только от participant на текст второй стороны; moderator
видит body только через аудируемый report context, а SUPPORT — только через
аудируемое обращение, привязанное к Booking. Pair-block отменяет только живые
`PENDING` и сохраняет активную аренду/evidence. `REVIEW` доступен для report
только после публикации; operator читает его текст через аудируемый context и
может скрыть без изменения Booking/финансов. Автор получает нейтральный event,
а lifecycle, appeal и retention зафиксированы в
[`review-policy.md`](review-policy.md).

До store submission остаются обязательными:

- versioned Terms/UGC rules и неотключаемое принятие до публикации;
- публичный контакт поддержки;
- подтверждённый operational SLA и runbook обработки жалоб;
- повторная проверка этих трёх официальных страниц непосредственно перед
  отправкой сборки.
