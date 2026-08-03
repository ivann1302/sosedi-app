# Store UGC requirements

Проверено: 29.07.2026. Использованы только официальные страницы магазинов.
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

## Состояние Sosedi

Backend уже имеет target-specific report, user block, rate/dedup, operator
`dismiss / hide listing / block user`, capability/CSRF и audit. Item проходит
премодерацию, изменение фото возвращает его на модерацию.

До store submission остаются обязательными:

- mobile UI с отдельными и явно подписанными действиями «Пожаловаться» и
  «Заблокировать»;
- versioned Terms/UGC rules и неотключаемое принятие до публикации;
- публичный контакт поддержки;
- подтверждённый operational SLA и runbook обработки жалоб;
- повторная проверка этих трёх официальных страниц непосредственно перед
  отправкой сборки.
