# Store readiness

Статус на 30.07.2026. Документ не хранит Apple Account, team ID, платежные
реквизиты, сертификаты или другие секреты.

## Идентификаторы приложений

Для production release зафиксирован единый идентификатор `ru.sosedi.app`:

- Android `namespace` и `applicationId`: `ru.sosedi.app`;
- iOS Runner bundle ID: `ru.sosedi.app`;
- iOS test bundle ID: `ru.sosedi.app.RunnerTests`.

Идентификатор должен использоваться при создании приложений в App Store
Connect, Google Play Console, RuStore и при ограничении provider API keys. После
первой публикации менять его нельзя.

## Apple Developer

Текущая проверка:

- Xcode 26.6 установлен;
- локальная keychain не содержит действующих code-signing identities;
- iOS bundle ID зафиксирован как `ru.sosedi.app`;
- подтверждения активного Apple Developer Program membership, Account Holder и
  даты продления в репозитории нет.

Пункт checklist остаётся `BLOCKED`, пока Account Holder не подтвердит:

1. статус `Active` и expiration date в Membership details;
2. тип membership: individual или organization;
3. включённое auto-renew либо доступную кнопку ручного продления;
4. реально доступный этому Account Holder платежный метод;
5. ссылку на закрытый operational record без номера карты, Apple Account и
   других персональных данных.

Apple указывает, что website membership продлевается Account Holder вручную
начиная за 30 дней до истечения либо через доступное для региона auto-renew.
При enrollment через Apple Developer app используется ежегодная
auto-renewable subscription и payment method Apple Account. Баланс Apple
Account в общем случае не принимается для membership.

Официальные источники:

- [Program Renewal](https://developer.apple.com/help/account/membership/renewal)
- [Program Enrollment](https://developer.apple.com/help/account/membership/program-enrollment)
- [Enrolling and renewing in the Apple Developer app](https://developer.apple.com/help/account/membership/enrolling-in-the-app)

Локальная повторная проверка:

```bash
xcodebuild -version
security find-identity -v -p codesigning
rg -n "PRODUCT_BUNDLE_IDENTIFIER|DEVELOPMENT_TEAM" mobile/ios/Runner.xcodeproj/project.pbxproj
```

Наличие сертификата локально не доказывает активность membership или
работоспособность продления; эти факты подтверждаются только в аккаунте.

## Android signing

Release variant больше не использует debug key. `make mobile-android-release`
до Flutter требует gitignored `mobile/android/key.properties` и указанный в нём
keystore как обычные файлы с mode `0600`; symlink, неполный набор свойств и
group/other access отклоняются. Файл содержит только локальные значения:

```properties
storeFile=/protected/path/sosedi-upload.jks
storePassword=FROM_SECRET_STORE
keyAlias=sosedi-upload
keyPassword=FROM_SECRET_STORE
```

Ключ и пароли не коммитятся, не попадают в checksum manifest и должны иметь
отдельную зашифрованную резервную копию. Само наличие локального keystore не
закрывает gate: нужны evidence создания приложения, upload key registration и
успешная внутренняя загрузка в Google Play/RuStore.

## iOS signing

`make mobile-ios-release` требует `IOS_DEVELOPMENT_TEAM` и путь
`IOS_EXPORT_OPTIONS_PLIST` к owner-only обычному XML-файлу. Wrapper проверяет
10-символьный Team ID, совпадение `<key>teamID</key>` и export method
`app-store-connect`, затем явно передаёт plist в `flutter build ipa`.
`Release.xcconfig` получает `DEVELOPMENT_TEAM` только из этого CI environment.
Файл не содержит private key, но хранится как protected signing metadata; без
действующих distribution certificate/provisioning profile сборка остаётся
заблокирована.

Локальный unsigned release smoke `make mobile-ios-smoke` успешно собрал
`Runner.app` для `ru.sosedi.app` 30.07.2026. CocoaPods работает строго по
`Podfile.lock`; отдельные `Debug`/`Release`/`Profile.xcconfig` подключают
соответствующие Pods-конфигурации, поэтому Profile не наследует release Pods
settings. Это подтверждает компиляцию, но не заменяет подпись, TestFlight и
проверку на реальном устройстве.

Текущий Firebase Apple SDK через CocoaPods предупреждает о прекращении публикации
новых CocoaPods-версий после октября 2026. До этой даты нужно отдельной
maintenance-задачей проверить поддерживаемый FlutterFire путь миграции; текущий
locked SDK собирается и не является основанием менять supply chain внутри этого
MVP-подэтапа.
