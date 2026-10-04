# Сборка и релиз приложения «Булак»

Пошаговая инструкция: от чистого окружения до готовых артефактов для Google Play и App Store.

**Параметры проекта:** Flutter-приложение `bulak`, Application ID / Bundle ID `kg.tlbk.bulak`, версия 1.0.0 (build 1), Android minSdk 23 / targetSdk 35, iOS 13.0+. **Флейворов в проекте нет** — все команды сборки выполняются без `--flavor`.

---

## 1. Требования к окружению

| Компонент | Версия / требование |
|---|---|
| Flutter | 3.47 или новее |
| Dart | 3.13 или новее (следует из `environment: sdk: ^3.13.0` в `pubspec.yaml`) |
| Android SDK | Platform 35, Build Tools актуальной версии |
| JDK | **17** — именно эту версию ожидает `android/app/build.gradle.kts` (`JavaVersion.VERSION_17`, JVM target 17) |
| Gradle | Поставляется с Flutter-шаблоном, отдельно устанавливать не нужно |
| Xcode | 15 или новее (для iOS-сборок), только macOS |
| CocoaPods | Актуальная версия (`sudo gem install cocoapods`) |
| Ruby | Требуется для CocoaPods |

### Проверка окружения

```bash
flutter --version
flutter doctor -v
java -version          # должно быть 17.x
```

`flutter doctor -v` должен показать зелёные галочки напротив Android toolchain и (на macOS) Xcode. Предупреждения о необязательных компонентах можно игнорировать.

Если `java -version` показывает не 17, укажите нужный JDK явно:

```bash
flutter config --jdk-dir="C:\Program Files\Java\jdk-17"
```

или, для macOS/Linux:

```bash
flutter config --jdk-dir=$(/usr/libexec/java_home -v 17)
```

---

## 2. Подготовка проекта

```bash
flutter pub get
flutter clean
flutter pub get
flutter analyze
flutter test
```

| Команда | Зачем |
|---|---|
| `flutter pub get` | Устанавливает зависимости из `pubspec.yaml` |
| `flutter clean` | Удаляет `build/` и `.dart_tool/` — полезно при странных ошибках сборки |
| `flutter analyze` | Статический анализ; перед релизом должно быть 0 ошибок и, желательно, 0 предупреждений |
| `flutter test` | Прогон тестов; перед релизом все тесты должны проходить |

Проверка версии, которая попадёт в сборку:

```bash
grep '^version:' pubspec.yaml      # macOS/Linux
Select-String '^version:' pubspec.yaml   # Windows PowerShell
```

Ожидаемый результат: `version: 1.0.0+1`. Подробнее о версионировании — в `docs/publishing/versioning.md`.

---

## 3. Подпись релизной сборки

**Обязательный шаг.** В текущем состоянии `android/app/build.gradle.kts` релизная сборка подписывается **отладочным ключом**:

```kotlin
// TODO: Add your own signing config for the release build.
// Signing with the debug keys for now, so `flutter run --release` works.
signingConfig = signingConfigs.getByName("debug")
```

Загрузить такую сборку в Google Play нельзя. Перед первым релизом:

1. Создайте keystore — см. `docs/publishing/signing.md`, раздел 2.
2. Создайте файл `android/key.properties` — он **не должен попадать в git**.
3. Замените блок `buildTypes` в `android/app/build.gradle.kts` на конфигурацию из `docs/publishing/signing.md`, раздел 4.
4. Создайте `android/key.properties.example` с примером-заполнителем (содержимое — в `docs/publishing/signing.md`, раздел 3); этот файл **можно** коммитить.

> Правило: если `key.properties` отсутствует, сборка должна либо падать с понятной ошибкой, либо осознанно откатываться на debug-ключ — но только для локальных сборок, никогда для релиза в стор.

---

## 4. Сборка Android

### 4.1. App Bundle для Google Play (основной артефакт)

```bash
flutter build appbundle --release
```

Артефакт: `build/app/outputs/bundle/release/app-release.aab`

Именно этот файл загружается в Play Console. Google Play сам формирует APK под конкретные устройства (в этом и смысл App Bundle), поэтому размер установки будет меньше, чем у универсального APK.

С явным указанием версии (если нужно переопределить pubspec):

```bash
flutter build appbundle --release --build-name=1.0.1 --build-number=2
```

### 4.2. APK для ручной установки и тестирования

Универсальный APK:

```bash
flutter build apk --release
```

Артефакт: `build/app/outputs/flutter-apk/app-release.apk`

Раздельные APK по архитектурам (меньше размер каждого):

```bash
flutter build apk --release --split-per-abi
```

Артефакты:

```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

> Для реальных устройств нужен `app-arm64-v8a-release.apk`. `x86_64` — для эмуляторов.

### 4.3. Проверка подписи APK

```bash
# Через apksigner из Android SDK build-tools
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk

# Либо через keytool
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

В выводе должен быть ваш релизный сертификат, а не `CN=Android Debug`.

### 4.4. Сборка AAB локально для проверки

```bash
# Собрать APK из AAB (нужен bundletool)
java -jar bundletool.jar build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=bulak.apks --mode=universal --ks=path/to/keystore.jks --ks-key-alias=upload
java -jar bundletool.jar install-apks --apks=bulak.apks
```

---

## 5. Сборка iOS

Выполняется только на macOS.

### 5.1. Подготовка

```bash
cd ios
pod install --repo-update
cd ..
```

Если `Podfile.lock` конфликтует, удалите `ios/Pods` и `ios/Podfile.lock` и повторите `pod install`.

### 5.2. Сборка без подписи (проверка компиляции)

```bash
flutter build ios --release --no-codesign
```

Полезно, чтобы убедиться, что проект собирается, не имея настроенных сертификатов.

### 5.3. Сборка IPA

```bash
flutter build ipa --release
```

Артефакты:

```
build/ios/ipa/bulak.ipa
build/ios/archive/Runner.xcarchive
```

С автоматическим экспортом через файл параметров:

```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

Содержимое `ExportOptions.plist` — в `docs/publishing/signing.md`, раздел 8.

### 5.4. Загрузка в App Store Connect

| Способ | Как |
|---|---|
| Xcode Organizer | `open build/ios/archive/Runner.xcarchive` → в Organizer выбрать архив → **Distribute App** → **App Store Connect** → **Upload** |
| Transporter | Открыть приложение Transporter, перетащить `build/ios/ipa/bulak.ipa`, нажать **Deliver** |
| Командная строка | `xcrun altool` устарел. Используйте Transporter или `xcodebuild -exportArchive` совместно с App Store Connect API key |
| CI | `xcrun notarytool` применяется для нотаризации macOS-приложений и в iOS-пайплайне не нужен; для iOS используйте Transporter или API-ключ |

Загрузка через API-ключ (рекомендуется для автоматизации):

```bash
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath build/ios/ipa \
  -allowProvisioningUpdates \
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_XXXXXXXXXX.p8 \
  -authenticationKeyID XXXXXXXXXX \
  -authenticationKeyIssuerID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## 6. Запуск на устройстве

### 6.1. Список устройств

```bash
flutter devices
flutter devices --device-timeout 20
```

### 6.2. Запуск в режиме отладки и профилирования

```bash
flutter run -d <device_id>
flutter run --profile -d <device_id>
flutter run --release -d <device_id>
```

### 6.3. Установка APK вручную

```bash
adb devices
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Удаление перед чистой установкой (полезно, чтобы проверить поведение первого запуска):

```bash
adb uninstall kg.tlbk.bulak
```

Просмотр логов:

```bash
adb logcat | findstr bulak        # Windows
adb logcat | grep bulak           # macOS/Linux
```

### 6.4. Установка сборки iOS на устройство

| Способ | Когда использовать |
|---|---|
| `flutter run --release -d <iphone_id>` | Быстрая проверка на подключённом устройстве с настроенной подписью |
| Xcode → Window → Devices and Simulators → перетащить IPA | Ручная установка |
| TestFlight | Проверка внешними тестировщиками до релиза |

---

## 7. Изменение версии и номера сборки

Версия хранится в `pubspec.yaml` в формате `MAJOR.MINOR.PATCH+BUILD`:

```yaml
version: 1.0.0+1
```

| Часть | Android | iOS |
|---|---|---|
| `1.0.0` (`versionName`) | `versionName = flutter.versionName` | `CFBundleShortVersionString` |
| `1` (`versionCode`) | `versionCode = flutter.versionCode` | `CFBundleVersion` |

Способы изменить версию:

**Вариант 1 — правка `pubspec.yaml` (рекомендуется):**

```yaml
version: 1.0.1+2
```

**Вариант 2 — флаги командной строки:**

```bash
flutter build appbundle --release --build-name=1.0.1 --build-number=2
flutter build ipa --release --build-name=1.0.1 --build-number=2
```

> Номер сборки (`build number`) должен **строго увеличиваться** при каждой загрузке в стор. Повторная загрузка того же номера будет отклонена: Google Play — «Version code already used», App Store — «The bundle version must be higher». Подробнее — `docs/publishing/versioning.md`.

Проверка того, что попало в сборку:

```bash
# Android — посмотреть версию в собранном APK (нужен aapt2 из build-tools)
aapt2 dump badging build/app/outputs/flutter-apk/app-release.apk | findstr version

# iOS — посмотреть версию в Info.plist собранного приложения
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" build/ios/iphoneos/Runner.app/Info.plist
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" build/ios/iphoneos/Runner.app/Info.plist
```

---

## 8. Обфускация

Dart-код можно обфусцировать, а символы отладки — вынести в отдельные файлы, чтобы по стектрейсам нельзя было восстановить структуру проекта.

### 8.1. Включение

```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols/android

flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/symbols/ios
```

**Обязательно сохраните каталог `build/symbols/`.** Без него вы не сможете разобрать стектрейсы из отчётов о сбоях. Храните символы для каждой выпущенной версии отдельно:

```
build/symbols/
├── android/
│   └── 1.0.0+1/
└── ios/
    └── 1.0.0+1/
```

> Каталог `build/` обычно исключён из git. Символы нужно складывать в защищённое хранилище (внутренний диск, приватный бакет) с резервной копией: потеря символов необратима.

### 8.2. Расшифровка стектрейса

```bash
flutter symbolize -i crash.trace -d build/symbols/android/1.0.0+1
```

Если пришёл символ-файл, а не каталог:

```bash
flutter symbolize -i crash.trace -d app.android-arm64.symbols
```

### 8.3. Отключение

Просто не указывайте флаги:

```bash
flutter build appbundle --release
```

### 8.4. Важные предупреждения

| Предупреждение | Последствие |
|---|---|
| Обфускация ломает рефлексию и динамический доступ к именам классов/полей | Если в проекте появится рефлексия или JSON-сериализация по именам полей, потребуются правила сохранения (`-keep`) |
| `--split-debug-info` без сохранения каталога символов | Стектрейсы станут нечитаемыми навсегда |
| На Android R8/minify может удалить нужные классы | Проверяйте релизную сборку на реальном устройстве полностью, а не только «запускается» |
| Обфускация не заменяет защиту секретов | Ключи и пароли не должны попадать в код ни до, ни после обфускации |

---

## 9. Размер сборки

### 9.1. Измерение

```bash
flutter build appbundle --release --analyze-size
flutter build apk --release --analyze-size --target-platform android-arm64
flutter build ipa --release --analyze-size
```

После сборки Flutter выведет разбор размера по компонентам и создаст JSON-файл, который можно загрузить в DevTools:

```bash
flutter pub global run devtools
# затем открыть вкладку App Size и загрузить созданный JSON
```

Для iOS можно посмотреть точный размер, открыв архив в Xcode Organizer → **App Store File Sizes**.

### 9.2. Где смотреть реальный размер для пользователя

| Платформа | Где смотреть |
|---|---|
| Google Play | Play Console → **Test and release → App bundle explorer** → выбрать версию → размеры по устройствам |
| App Store | App Store Connect → **TestFlight** → выбрать сборку → раздел с размером; либо Xcode Organizer |

### 9.3. Как уменьшать размер

| Приём | Эффект |
|---|---|
| Использовать App Bundle вместо универсального APK | Пользователь скачивает только нужную архитектуру |
| `flutter build apk --split-per-abi` | То же для прямой раздачи |
| `--split-debug-info` | Убирает отладочную информацию из бинарника |
| Исключить неиспользуемые ресурсы | Не хранить изображения, которых нет в интерфейсе |
| Tree-shake иконок | Material-иконки обрезаются автоматически при `--tree-shake-icons` (включено в релизе по умолчанию) |
| Оптимизировать изображения | PNG → WebP там, где это возможно; убирать изображения больше 1024 px по ширине |
| Убрать неиспользуемые зависимости | Каждый плагин добавляет нативный код |

---

## 10. Что делать при ошибках

### 10.1. Android

| Симптом | Причина | Решение |
|---|---|---|
| `Unsupported class file major version` / `Execution failed for task ':app:compileReleaseKotlin'` | Неверная версия JDK | Установить JDK 17 и выполнить `flutter config --jdk-dir=...` |
| `Keystore file not found for signing config 'release'` | Путь в `key.properties` указан неверно | Проверить `storeFile`, использовать прямые слэши `C:/.../upload.jks` или двойные обратные |
| `Keystore was tampered with, or password was incorrect` | Неверный пароль в `key.properties` | Проверить `storePassword` и `keyPassword` (они могут отличаться) |
| `Execution failed for task ':app:lintVitalRelease'` | Lint нашёл проблему в релизной сборке | Исправить замечание либо, как временную меру, добавить в `android/app/build.gradle.kts` блок `lint { checkReleaseBuilds = false }` |
| `Version code 1 has already been used` | Номер сборки не увеличен | Увеличить `+N` в `pubspec.yaml` |
| `One or more plugins require a higher Android SDK version` | Плагин требует более новый `minSdk` | Проверить требование плагина и при необходимости поднять `minSdk` (текущий — 23) |
| `Android Gradle plugin requires Java 17` | См. первую строку | То же |
| `Could not resolve all dependencies` / `Could not download ...` | Проблема с сетью или прокси | Проверить подключение, повторить `flutter pub get`, очистить `~/.gradle/caches` |
| `OutOfMemoryError` при сборке | Мало памяти Gradle | В `android/gradle.properties` уже стоит `-Xmx8G`; при нехватке RAM уменьшить до `-Xmx4G` |
| `adb: device unauthorized` | Не подтверждена отладка на устройстве | Подтвердить запрос на экране устройства |

### 10.2. iOS

| Симптом | Причина | Решение |
|---|---|---|
| `No valid code signing certificates were found` | Нет сертификата в связке ключей | Создать сертификат в Apple Developer, установить его, выбрать Team в Xcode |
| `Provisioning profile doesn't match the entitlements` | Профиль не соответствует возможностям приложения | Пересоздать профиль в Developer Portal, включить автоматическое управление подписью |
| `error: The operation couldn't be completed. (CocoaPods)` | Проблема с CocoaPods | `cd ios && pod repo update && pod install`; при неудаче удалить `ios/Pods` и `ios/Podfile.lock` |
| `Missing Purpose String in Info.plist` | Приложение запрашивает доступ, не описав его | Добавить соответствующую строку в `Info.plist` с понятным объяснением |
| `The bundle version must be higher than the previously uploaded version` | Номер сборки не увеличен | Увеличить `+N` в `pubspec.yaml` |
| `Invalid Bundle. The bundle at ... does not contain a supported architecture` | Неверная архитектура или повреждённый архив | Пересобрать: `flutter clean && flutter build ipa --release` |
| `ITMS-90474: Invalid Bundle` | Не хватает иконки нужного размера | Проверить `Assets.xcassets/AppIcon.appiconset` |
| `Command PhaseScriptExecution failed` | Ошибка в скрипте сборки Flutter | Часто помогает `flutter clean` и повторный `pod install`; проверить путь к Flutter в Xcode (`FLUTTER_ROOT`) |
| `Deployment target 13.0 is not supported` | Несоответствие минимальной версии | Проверить `ios/Podfile` (`platform :ios, '13.0'`) и настройки Xcode |

### 10.3. Общие

| Симптом | Причина | Решение |
|---|---|---|
| `flutter pub get` зависает | Проблема с сетью или зеркалом pub.dev | Проверить прокси/VPN, повторить |
| `Because ... depends on ... version solving failed` | Конфликт версий зависимостей | `flutter pub upgrade --major-versions` или зафиксировать совместимые версии |
| Приложение падает только в релизе, в отладке работает | R8/minify или обфускация удалили нужный код | Собрать с `--split-debug-info`, разобрать стектрейс, добавить `-keep`-правила |
| `flutter clean` не помог | Остались кэши | Дополнительно удалить `.dart_tool/`, `android/.gradle/`, `ios/Pods/` |
| Сборка внезапно начала падать после обновления Flutter | Изменения в шаблонах Gradle/Info.plist | Сравнить `android/` и `ios/` с новым шаблоном (`flutter create .` в отдельной копии проекта) |

**Общий порядок диагностики при любой непонятной ошибке сборки:**

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..   # только для iOS
flutter build appbundle --release --verbose
```

Флаг `--verbose` показывает полный лог, включая команды Gradle и Xcode.

---

## 11. CI (GitHub Actions) — только описание

Файлы воркфлоу в этом репозитории **не создаются**: каталог `.github/` не входит в зону ответственности документации. Ниже — описание того, как автоматизировать сборку, когда вы решите это сделать.

### 11.1. Что хранить в GitHub Secrets

| Секрет | Содержимое |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Файл keystore, закодированный в base64 (`base64 -w0 upload.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | Пароль хранилища |
| `ANDROID_KEY_PASSWORD` | Пароль ключа |
| `ANDROID_KEY_ALIAS` | `upload` |
| `IOS_CERTIFICATE_BASE64` | Сертификат распространения в base64 (`.p12`) |
| `IOS_CERTIFICATE_PASSWORD` | Пароль `.p12` |
| `IOS_PROVISIONING_PROFILE_BASE64` | Профиль provisioning в base64 |
| `APPSTORE_API_KEY_ID` | ID ключа App Store Connect API |
| `APPSTORE_API_ISSUER_ID` | Issuer ID |
| `APPSTORE_API_PRIVATE_KEY` | Содержимое `.p8` |

### 11.2. Типовой пайплайн

| Этап | Действия |
|---|---|
| 1. Checkout | `actions/checkout@v4` |
| 2. Flutter | `subosito/flutter-action@v2` с нужной версией |
| 3. Зависимости | `flutter pub get` |
| 4. Анализ | `flutter analyze` |
| 5. Тесты | `flutter test` |
| 6. Расшифровка keystore | Записать base64 в файл, декодировать, создать `android/key.properties` |
| 7. Сборка Android | `flutter build appbundle --release --split-debug-info=build/symbols` |
| 8. Артефакты | `actions/upload-artifact@v4` для AAB и каталога символов |
| 9. iOS | `apple-actions/import-codesign-certs@v3`, `apple-actions/download-provisioning-profiles@v3` |
| 10. Сборка iOS | `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist` |
| 11. Публикация | `r0adkll/upload-google-play@v1` для Play; Transporter или API-ключ для App Store Connect |

### 11.3. Правила безопасности в CI

- Никогда не печатать в лог содержимое `key.properties`, пароли и base64-секреты.
- Не коммитить `key.properties`, `*.jks`, `*.keystore`, `.p8`, `.p12`, `.mobileprovision`.
- Символы обфускации сохранять как артефакт сборки с ограниченным доступом.
- Для секретов, попадающих в код, использовать `--dart-define` и `String.fromEnvironment`; значения передавать из GitHub Secrets.
- Ограничить доступ к секретам только нужными воркфлоу и не запускать сборку релиза по pull request из форка.

---

## 12. Финальный чек-лист сборки

- [ ] `flutter analyze` без ошибок.
- [ ] `flutter test` — все тесты проходят.
- [ ] Версия в `pubspec.yaml` увеличена, номер сборки больше предыдущего.
- [ ] Релизная сборка Android подписана **релизным** ключом (проверено через `apksigner verify`).
- [ ] Каталог символов `build/symbols/` сохранён в защищённом месте.
- [ ] AAB собран и проверен в Play Console → App bundle explorer.
- [ ] IPA собран и загружен в App Store Connect.
- [ ] Сборка установлена и проверена на реальном устройстве, а не только в эмуляторе.
- [ ] Проверено поведение без интернета.
- [ ] Проверены родительский PIN, дневной лимит и «Сбросить всё».
- [ ] `key.properties` и keystore отсутствуют в git-истории.
