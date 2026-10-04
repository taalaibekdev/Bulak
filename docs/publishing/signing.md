# Подпись приложения «Булак»: Android и iOS

Документ описывает создание ключей подписи, настройку Gradle, работу с Play App Signing, сертификаты и профили provisioning для iOS и безопасное хранение секретов.

**Текущее состояние проекта:** релизная сборка Android в `android/app/build.gradle.kts` **пока подписана отладочным ключом**:

```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        // Signing with the debug keys for now, so `flutter run --release` works.
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

Это допустимо для локальной проверки `flutter run --release`, но **недопустимо для загрузки в Google Play**. Шаги ниже нужно выполнить до первого релиза.

---

## 1. Что нужно сделать (краткий план)

| № | Шаг | Файл / результат |
|---|---|---|
| 1 | Создать keystore командой `keytool` | `bulak-upload.jks` (вне репозитория) |
| 2 | Создать `android/key.properties` с паролями и путём | `android/key.properties` (в `.gitignore`) |
| 3 | Создать `android/key.properties.example` | пример для новых разработчиков |
| 4 | Изменить `android/app/build.gradle.kts` | релизная подпись из `key.properties` |
| 5 | Включить Play App Signing | в Play Console при первой загрузке |
| 6 | Настроить iOS-сертификаты и профили | Apple Developer Portal + Xcode |
| 7 | Создать `ios/ExportOptions.plist` | параметры экспорта IPA |
| 8 | Настроить секреты CI | GitHub Secrets |

---

## 2. Создание keystore (Android)

### 2.1. Куда сохранять файл

**Никогда не сохраняйте keystore внутри репозитория.** Используйте отдельный каталог вне проекта:

| ОС | Рекомендуемый путь |
|---|---|
| Windows | `C:\Users\<имя>\keys\bulak-upload.jks` |
| macOS / Linux | `/Users/<имя>/keys/bulak-upload.jks` или `~/keys/bulak-upload.jks` |

Сделайте резервную копию файла в двух независимых местах (например, защищённый облачный бакет и зашифрованный внешний диск). **Потеря upload key означает необходимость запроса на сброс ключа в Google Play.**

### 2.2. Команда создания

Windows (PowerShell или cmd):

```powershell
keytool -genkeypair -v ^
  -keystore C:\Users\<имя>\keys\bulak-upload.jks ^
  -storetype JKS ^
  -keyalg RSA -keysize 2048 -validity 10000 ^
  -alias upload
```

macOS / Linux:

```bash
keytool -genkeypair -v \
  -keystore ~/keys/bulak-upload.jks \
  -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

### 2.3. Что ответить на вопросы keytool

| Вопрос | Рекомендуемый ответ |
|---|---|
| Enter keystore password | Надёжный пароль (не менее 16 символов), сохранённый в менеджере паролей |
| Re-enter new password | Тот же пароль |
| What is your first and last name? | Полное имя владельца или название организации |
| What is the name of your organizational unit? | `Mobile` или название подразделения |
| What is the name of your organization? | `tlbk.kg` <!-- заполнить перед публикацией: точное юридическое наименование --> |
| What is the name of your City or Locality? | Город регистрации |
| What is the name of your State or Province? | Область/регион |
| What is the two-letter country code for this unit? | `KG` |
| Is CN=..., OU=..., O=..., L=..., ST=..., C=KG correct? | `yes` |
| Enter key password for <upload> | Нажмите Enter, чтобы использовать тот же пароль, что и для хранилища (упрощает настройку), либо задайте отдельный |

> **Важно:** если для ключа задан отдельный пароль, в `key.properties` нужно указать оба: `storePassword` и `keyPassword`.

### 2.4. Проверка созданного keystore

```bash
keytool -list -v -keystore ~/keys/bulak-upload.jks -alias upload
```

В выводе должны быть `Alias name: upload`, `Valid from: ... until: ...` (срок около 27 лет при `-validity 10000`) и отпечатки `SHA1` / `SHA256`. Сохраните отпечатки в защищённом месте: они понадобятся для настройки Google Sign-In и подобных сервисов (в «Булаке» они не используются, но пригодятся в будущем).

### 2.5. Кодирование в base64 (для CI)

```bash
base64 -w0 ~/keys/bulak-upload.jks > bulak-upload.jks.base64     # Linux
base64 -i ~/keys/bulak-upload.jks -o bulak-upload.jks.base64    # macOS
certutil -encode bulak-upload.jks bulak-upload.jks.base64       # Windows
```

Полученную строку добавьте в GitHub Secrets как `ANDROID_KEYSTORE_BASE64`. Сам файл `.base64` после этого удалите.

---

## 3. Файл `android/key.properties`

Создайте файл `android/key.properties` со следующим содержимым:

```properties
storePassword=<пароль_хранилища>
keyPassword=<пароль_ключа>
keyAlias=upload
storeFile=C:/Users/<имя>/keys/bulak-upload.jks
```

### Правила заполнения

| Ключ | Значение | Замечания |
|---|---|---|
| `storePassword` | Пароль keystore | Совпадает с введённым в `keytool` |
| `keyPassword` | Пароль ключа | Если при создании нажали Enter — совпадает с `storePassword` |
| `keyAlias` | `upload` | Именно тот alias, что указан в `keytool -alias` |
| `storeFile` | Абсолютный путь к `.jks` | **Используйте прямые слэши `/`**, даже на Windows: `C:/Users/name/keys/bulak-upload.jks`. Обратные слэши нужно экранировать (`C:\\Users\\...`), что часто приводит к ошибкам |

### Файл `android/key.properties.example` (создать)

Создайте в каталоге `android/` файл `key.properties.example` — он **коммитится** и служит инструкцией для новых разработчиков:

```properties
# Пример файла подписи для релизной сборки Android.
#
# Скопируйте этот файл в android/key.properties и заполните реальными значениями.
# Файл android/key.properties НЕ должен попадать в git (он в .gitignore).
#
# Как создать keystore — см. docs/publishing/signing.md, раздел 2.

# Пароль хранилища ключей (keystore)
storePassword=CHANGE_ME_store_password

# Пароль самого ключа. Если совпадает с паролем хранилища — укажите то же значение.
keyPassword=CHANGE_ME_key_password

# Alias ключа, заданный при создании через keytool -alias
keyAlias=upload

# Абсолютный путь к файлу .jks. ВСЕГДА используйте прямые слэши "/".
# Windows:  storeFile=C:/Users/yourname/keys/bulak-upload.jks
# macOS:    storeFile=/Users/yourname/keys/bulak-upload.jks
# Linux:    storeFile=/home/yourname/keys/bulak-upload.jks
storeFile=/absolute/path/to/bulak-upload.jks
```

> Файл `android/key.properties.example` создаётся вручную в каталоге `android/`. Он не создаётся автоматически и должен быть добавлен в git.

---

## 4. Настройка `android/app/build.gradle.kts`

Файл использует **Kotlin DSL** (`.kts`), поэтому синтаксис отличается от привычного Groovy. Ниже — полный рабочий пример с сохранением текущих настроек проекта (`namespace`, `applicationId`, Java 17, версии из Flutter).

```kotlin
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// --- Чтение параметров подписи из android/key.properties ---
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "kg.tlbk.bulak"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "kg.tlbk.bulak"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // --- Конфигурация релизной подписи ---
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Релиз подписывается релизным ключом, если он настроен.
            // Если key.properties отсутствует, используется debug-ключ —
            // это допустимо только для локальной проверки, но не для Google Play.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "ВНИМАНИЕ: android/key.properties не найден. " +
                        "Релизная сборка подписывается ОТЛАДОЧНЫМ ключом и не может быть " +
                        "загружена в Google Play. См. docs/publishing/signing.md"
                )
                signingConfigs.getByName("debug")
            }

            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
```

### Что здесь важно

| Элемент | Пояснение |
|---|---|
| `import java.util.Properties` | Импорты в Kotlin DSL размещаются **до** блока `plugins` |
| `rootProject.file("key.properties")` | Файл лежит в `android/key.properties`, а `rootProject` — это каталог `android/` |
| `signingConfigs { create("release") { ... } }` | В Kotlin DSL используется `create(...)`, а не `release { ... }` |
| `isMinifyEnabled` / `isShrinkResources` | Включение R8 и удаления неиспользуемых ресурсов; в Groovy это `minifyEnabled` / `shrinkResources` |
| Защита от отсутствия файла | Явное предупреждение в логе, чтобы никто случайно не загрузил debug-подписанную сборку |

### Строгий вариант (сборка падает без ключа)

Если вы предпочитаете, чтобы релизная сборка **не собиралась** без ключа, замените блок так:

```kotlin
buildTypes {
    release {
        if (!keystorePropertiesFile.exists()) {
            throw GradleException(
                "Не найден android/key.properties. " +
                    "Релизная сборка невозможна без параметров подписи. " +
                    "См. docs/publishing/signing.md"
            )
        }
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
    }
}
```

> Для CI рекомендуется именно строгий вариант: он исключает случайную публикацию неправильно подписанной сборки.

---

## 5. Что добавить в `.gitignore`

Файл `.gitignore` в корне репозитория **не изменяется** в рамках этой документации, но в него нужно добавить строки:

```gitignore
# Подпись Android
android/key.properties
**/*.jks
**/*.keystore

# Символы обфускации
build/symbols/

# Подпись iOS
ios/*.mobileprovision
ios/*.p12
*.p8
```

Проверка, что секреты не попали в git-историю:

```bash
git log --all --full-history -- "**/key.properties"
git log --all --full-history -- "*.jks"
git ls-files | grep -E "key.properties|\.jks$"
```

Если секрет уже закоммичен, одного удаления файла недостаточно: пароли нужно **сменить**, ключ — перевыпустить, а историю — переписать (`git filter-repo`). Старый ключ, попавший в публичный репозиторий, считается скомпрометированным.

---

## 6. Play App Signing

Google Play использует двухключевую схему.

| Ключ | Кто хранит | Назначение |
|---|---|---|
| **Upload key** (ключ загрузки) | Вы | Им подписывается AAB, который вы загружаете в Play Console |
| **App signing key** (ключ подписи приложения) | Google | Им Google подписывает APK, которые получают пользователи |

### Как это работает

1. Вы загружаете AAB, подписанный upload-ключом.
2. Google проверяет подпись, затем **переподписывает** сборку своим app signing ключом.
3. Пользователи устанавливают сборку, подписанную app signing ключом Google.
4. При обновлении приложения подпись остаётся той же, потому что app signing ключ не меняется.

### Включение при первой загрузке

**Новые приложения** (созданные в Play Console после августа 2021 года) включают Play App Signing **автоматически и необратимо**. При первой загрузке AAB Play Console покажет экран с выбором: согласиться на управление ключом подписи приложения со стороны Google (рекомендуется) или загрузить собственный app signing key.

**Рекомендация:** согласиться на управление Google. Это защищает от потери ключа подписи приложения: если upload-ключ утерян, его можно сбросить, а потерю app signing key восстановить невозможно.

### Что делать при потере upload key

1. Создайте новый keystore командой `keytool` (раздел 2).
2. В Play Console откройте: **Release → Setup → App signing**.
3. Нажмите **Request upload key reset** и загрузите сертификат нового ключа (файл `.pem`).
4. Дождитесь одобрения Google (обычно несколько дней).
5. После сброса все последующие сборки подписываются новым upload-ключом.

Получить `.pem` из нового keystore:

```bash
keytool -export -rfc -keystore ~/keys/bulak-upload-new.jks -alias upload -file upload_certificate.pem
```

### Чего нельзя делать

| Нельзя | Почему |
|---|---|
| Перевыпустить приложение с другим app signing key | Google Play не примет обновление: подпись должна совпадать |
| Загружать AAB, подписанный debug-ключом | Play отклонит сборку |
| Хранить app signing key только в одном месте | Его потеря означает невозможность обновлять приложение |
| Публиковать пароли к ключам в репозитории или CI-логах | Компрометация ключа подписи |

---

## 7. iOS: сертификаты и профили provisioning

### 7.1. Что нужно создать в Apple Developer Portal

| Ресурс | Где создаётся | Назначение |
|---|---|---|
| **App ID** | Certificates, Identifiers & Profiles → Identifiers | Bundle ID `kg.tlbk.bulak`; тип — Explicit App ID |
| **Apple Development** сертификат | Certificates → + → Apple Development | Для запуска на устройстве при разработке |
| **Apple Distribution** сертификат | Certificates → + → Apple Distribution | Для загрузки в App Store |
| **Development provisioning profile** | Profiles → + → iOS App Development | Для отладки на устройстве |
| **Ad Hoc provisioning profile** | Profiles → + → Ad Hoc | Для ручной раздачи тестировщикам |
| **App Store provisioning profile** | Profiles → + → App Store | Для загрузки в App Store Connect |

### 7.2. Создание сертификата

1. На macOS откройте **Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority**.
2. Укажите e-mail, имя, выберите **Saved to disk**, сохраните `CertificateSigningRequest.certSigningRequest`.
3. В Apple Developer Portal: **Certificates → + → Apple Distribution**, загрузите CSR, скачайте `.cer`.
4. Дважды кликните по `.cer` — сертификат установится в связку ключей.
5. Экспортируйте его как `.p12` (**Keychain Access → My Certificates → Export**), задав пароль. Этот `.p12` понадобится для CI.

### 7.3. Настройка Xcode

1. Откройте `ios/Runner.xcworkspace` (именно `.xcworkspace`, не `.xcodeproj`).
2. Выберите проект **Runner** → вкладка **Signing & Capabilities**.
3. Укажите:
   - **Team** — вашу команду разработчика;
   - **Bundle Identifier** — `kg.tlbk.bulak`;
   - **Deployment Target** — `13.0`;
   - **Automatically manage signing** — включено (для локальной разработки это проще всего).
4. Проверьте, что в **Info.plist** задано отображаемое имя:

```xml
<key>CFBundleDisplayName</key>
<string>Булак</string>
```

5. Убедитесь, что в `Info.plist` **нет** лишних разрешений и ключа `NSUserTrackingUsageDescription` (приложение не отслеживает пользователя).

### 7.4. App Transport Security

Приложение обращается к YouTube по HTTPS, поэтому **не нужно** отключать ATS. Не добавляйте `NSAllowsArbitraryLoads`. Если ATS когда-либо потребует исключений, они должны быть узкими и обоснованными.

### 7.5. Автоматическая vs ручная подпись

| Режим | Плюсы | Минусы |
|---|---|---|
| Automatic (`Automatically manage signing`) | Xcode сам создаёт сертификаты и профили; быстро для локальной работы | Требует входа в аккаунт в Xcode; в CI неудобен |
| Manual | Полный контроль; подходит для CI | Нужно вручную создавать и обновлять профили |

Рекомендация: локально — автоматическая подпись, в CI — ручная с установкой `.p12` и профилей из секретов.

---

## 8. `ios/ExportOptions.plist`

Этот файл передаётся в `flutter build ipa --export-options-plist=ios/ExportOptions.plist` и определяет, как именно экспортируется IPA.

Создайте `ios/ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Способ распространения: app-store для загрузки в App Store Connect -->
    <key>method</key>
    <string>app-store</string>

    <!-- Идентификатор команды разработчика -->
    <key>teamID</key>
    <string>XXXXXXXXXX</string>

    <!-- Автоматическое управление подписью во время экспорта -->
    <key>signingStyle</key>
    <string>automatic</string>

    <!-- Для ручной подписи вместо signingStyle используйте:
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>kg.tlbk.bulak</key>
        <string>Bulak App Store Profile</string>
    </dict>
    -->

    <!-- Не загружать символы dSYM отдельным шагом -->
    <key>uploadSymbols</key>
    <true/>

    <!-- Не загружать биткод: современные Xcode его не используют -->
    <key>uploadBitcode</key>
    <false/>

    <!-- Собирать биткод при экспорте -->
    <key>compileBitcode</key>
    <false/>

    <!-- Управление версией и номером сборки берёт на себя Flutter -->
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
</dict>
</plist>
```

| Параметр | Что делает |
|---|---|
| `method` | `app-store` — для App Store; `ad-hoc` — для ручной раздачи; `development` — для отладки; `enterprise` — для корпоративной программы |
| `teamID` | 10-символьный идентификатор команды из Apple Developer Portal |
| `signingStyle` | `automatic` или `manual` |
| `provisioningProfiles` | Соответствие Bundle ID → имени профиля; требуется при ручной подписи |
| `uploadSymbols` | Загружать dSYM для символизации крашей — рекомендуется `true` |
| `manageAppVersionAndBuildNumber` | Оставьте `false`, чтобы Flutter управлял версией из `pubspec.yaml` |

<!-- заполнить перед публикацией: указать реальный teamID команды Apple Developer -->

---

## 9. App Store Connect API Key (для автоматизации)

Вместо Apple ID и пароля для автоматических загрузок используйте API-ключ.

1. App Store Connect → **Users and Access → Integrations → App Store Connect API → Team Keys**.
2. Нажмите **+**, задайте имя, выберите роль **App Manager**.
3. Скачайте `.p8` — **файл можно скачать только один раз**.
4. Запишите **Key ID** и **Issuer ID**.

Размещение ключа локально:

```bash
mkdir -p ~/.appstoreconnect/private_keys
mv ~/Downloads/AuthKey_XXXXXXXXXX.p8 ~/.appstoreconnect/private_keys/
```

Проверка:

```bash
ls ~/.appstoreconnect/private_keys/
```

Использование в CI: содержимое `.p8` помещается в секрет `APPSTORE_API_PRIVATE_KEY`, при сборке записывается в файл тем же путём.

---

## 10. Безопасное хранение секретов в GitHub Actions

### 10.1. Список секретов

| Секрет | Как получить | Как использовать |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload.jks` | Декодировать в файл, указать путь в `key.properties` |
| `ANDROID_KEYSTORE_PASSWORD` | Пароль keystore | Записать в `key.properties` |
| `ANDROID_KEY_PASSWORD` | Пароль ключа | Записать в `key.properties` |
| `ANDROID_KEY_ALIAS` | `upload` | Записать в `key.properties` |
| `IOS_CERTIFICATE_BASE64` | `.p12` в base64 | Импортировать через `apple-actions/import-codesign-certs` |
| `IOS_CERTIFICATE_PASSWORD` | Пароль `.p12` | Передать в тот же экшен |
| `IOS_PROVISIONING_PROFILE_BASE64` | `.mobileprovision` в base64 | Загрузить через `apple-actions/download-provisioning-profiles` |
| `APPSTORE_API_KEY_ID` | App Store Connect API | Идентификация ключа |
| `APPSTORE_API_ISSUER_ID` | App Store Connect API | Идентификация ключа |
| `APPSTORE_API_PRIVATE_KEY` | Содержимое `.p8` | Загрузить в App Store Connect |

### 10.2. Пример декодирования keystore в CI (только описание)

| Шаг | Команда |
|---|---|
| Декодировать keystore | `echo "$ANDROID_KEYSTORE_BASE64" \| base64 --decode > $RUNNER_TEMP/bulak-upload.jks` |
| Создать `key.properties` | Записать в `android/key.properties` четыре строки, подставив значения из секретов и путь `$RUNNER_TEMP/bulak-upload.jks` |
| Собрать | `flutter build appbundle --release --split-debug-info=build/symbols/android` |
| Удалить keystore после сборки | `rm -f $RUNNER_TEMP/bulak-upload.jks` (шаг `if: always()`) |

### 10.3. Правила безопасности

| Правило | Причина |
|---|---|
| Никогда не печатать секреты в лог | Логи CI могут быть доступны шире, чем предполагается |
| Не передавать секреты в `--dart-define` без необходимости | Значения попадают в бинарник |
| Не запускать релизные воркфлоу по pull request из форков | Форк может изменить код и получить доступ к секретам |
| Ограничить секреты конкретными окружениями (GitHub Environments) | Требует ручного подтверждения для продакшена |
| Хранить символы обфускации как защищённый артефакт | Символы позволяют восстановить структуру кода |
| Ротировать пароли при увольнении участника | Стандартная гигиена |
| Использовать отдельные ключи для CI и для локальной сборки | Упрощает отзыв при компрометации |

---

## 11. Чек-лист подписи

- [ ] Keystore создан и сохранён **вне** репозитория.
- [ ] Резервная копия keystore сделана в двух независимых местах.
- [ ] Пароли сохранены в менеджере паролей, а не в переписке.
- [ ] `android/key.properties` создан и добавлен в `.gitignore`.
- [ ] `android/key.properties.example` создан и закоммичен.
- [ ] `android/app/build.gradle.kts` использует релизную подпись из `key.properties`.
- [ ] Строки для `.gitignore` добавлены (`key.properties`, `*.jks`, `*.keystore`).
- [ ] Проверено, что секреты не попали в git-историю.
- [ ] Релизная сборка проверена командой `apksigner verify --print-certs`.
- [ ] Play App Signing включён, app signing key хранится у Google.
- [ ] Для iOS созданы сертификаты Apple Development и Apple Distribution.
- [ ] Созданы профили provisioning: Development, Ad Hoc, App Store.
- [ ] Bundle ID в Xcode совпадает с `kg.tlbk.bulak`.
- [ ] `ios/ExportOptions.plist` создан и содержит корректный `teamID`.
- [ ] App Store Connect API Key создан, `.p8` сохранён в защищённом месте.
- [ ] Секреты добавлены в GitHub Secrets, а не в файлы репозитория.
