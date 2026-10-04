# fastlane — метаданные магазинов «Булак»

Эта папка содержит **готовые к загрузке** метаданные для Google Play и App Store в формате fastlane.
Тексты взяты из документации в `docs/store/` — там они написаны и вычитаны; здесь они разложены
по файлам с именами, которых ждут `fastlane supply` (Google Play) и `fastlane deliver` (App Store).

```
fastlane/
├── README.md                     ← этот файл
├── metadata/
│   ├── android/                  ← Google Play (fastlane supply)
│   │   ├── ru-RU/
│   │   │   ├── title.txt                  название, ≤ 30 символов
│   │   │   ├── short_description.txt      краткое описание, ≤ 80 символов
│   │   │   ├── full_description.txt       полное описание, ≤ 4000 символов, чистый текст
│   │   │   ├── changelogs/1.txt           «что нового» для versionCode 1
│   │   │   └── images/                    ← картинки (см. ниже)
│   │   │       ├── icon/                  512 × 512 PNG, без альфа-канала
│   │   │       ├── featureGraphic/        1024 × 500
│   │   │       ├── phoneScreenshots/      1080 × 1920, 2–8 файлов (в проекте — минимум 4)
│   │   │       └── tenInchScreenshots/    1920 × 1200
│   │   └── en-US/                ← то же самое для английского листинга
│   └── ios/                      ← App Store (fastlane deliver)
│       ├── ru/
│       │   ├── name.txt                   название, ≤ 30
│       │   ├── subtitle.txt               подзаголовок, ≤ 30
│       │   ├── keywords.txt               ключевые слова, ≤ 100, через запятую без пробелов
│       │   ├── promotional_text.txt       промотекст, ≤ 170
│       │   ├── description.txt            описание, ≤ 4000, чистый текст
│       │   ├── release_notes.txt          «что нового» в 1.0.0
│       │   ├── privacy_url.txt            https://bulak.tlbk.kg/privacy
│       │   ├── support_url.txt            https://bulak.tlbk.kg
│       │   └── marketing_url.txt          https://bulak.tlbk.kg
│       └── en-US/                ← то же самое для английской локализации
└── screenshots/                  ← скриншоты iOS (fastlane snapshot / deliver)
    ├── ru/
    └── en-US/
```

## Как связаны `docs/store/...` и `fastlane/...`

| Откуда взят текст | Куда он попал |
|---|---|
| `docs/store/google-play/listing.ru.md` | `fastlane/metadata/android/ru-RU/{title,short_description,full_description}.txt` |
| `docs/store/google-play/listing.en.md` | `fastlane/metadata/android/en-US/{title,short_description,full_description}.txt` |
| `docs/store/app-store/listing.ru.md` | `fastlane/metadata/ios/ru/*.txt` |
| `docs/store/app-store/listing.en.md` | `fastlane/metadata/ios/en-US/*.txt` |
| `docs/store/google-play/store-assets.md` | `fastlane/metadata/android/*/images/*/README.md` |
| `docs/store/screenshots-plan.md` | `fastlane/metadata/android/*/images/*/README.md`, `fastlane/screenshots/*/README.md` |

Поля, которые **не имеют** отдельного файла в fastlane, заполняются руками в консоли магазина:
категории, теги, возрастные группы, анкеты Data safety / Age Rating, адреса распространения,
имя продавца и юридические данные. Они описаны в разделах 5–10 файлов `docs/store/*/listing.*.md`.

**Тексты в `fastlane/` — копия документов.** Если правите формулировку, меняйте её в **двух местах**:
в `docs/store/...` (первоисточник, там же пересчитываются длины) и в соответствующем файле `fastlane/...`.
Либо примите `docs/store/` за единственный источник правды и копируйте оттуда скриптом.
Разошедшиеся копии — самая частая причина, по которой в стор уходит старая формулировка.

## Что нужно доложить руками

Скрипт подготовил только **текст**. Картинки в репозитории не лежат — их нужно изготовить и положить
в соответствующие папки (в каждой уже есть `README.md` с точной спецификацией размера и содержания):

| Что | Куда | Требование |
|---|---|---|
| Иконка Play | `metadata/android/<locale>/images/icon/icon.png` | 512 × 512 PNG, без альфа-канала, ≤ 1 МБ |
| Feature graphic | `metadata/android/<locale>/images/featureGraphic/featureGraphic.png` | 1024 × 500, центр свободен под кнопку видео |
| Скриншоты телефона | `metadata/android/<locale>/images/phoneScreenshots/1..8.png` | 1080 × 1920, 6–8 штук |
| Скриншоты 10" планшета | `metadata/android/<locale>/images/tenInchScreenshots/1..6.png` | 1920 × 1200 (или 1600 × 2560) |
| Скриншоты iOS | `fastlane/screenshots/<locale>/` | iPhone 1320 × 2868 и 1290 × 2796, iPad 2064 × 2752 |

Скриншоты снимаются **с реальной сборки 1.0.0**, подписи накладываются в графическом редакторе.
Полный план кадров, подписи RU/EN, палитра и список запрещённого — в `docs/store/screenshots-plan.md`
и `docs/store/google-play/store-assets.md`. 7" планшетные скриншоты Play считает желательными
(папка в формате supply — `images/sevenInchScreenshots/`), в этом наборе они не заведены.

## Проверка перед загрузкой

- [ ] Повторная проверка длин (внешним скриптом) подтверждает: ни один текстовый файл не превышает лимит магазина.
- [ ] Все файлы в UTF-8 **без BOM**, перевод строки в конце файла.
- [ ] В `full_description.txt` и `description.txt` нет Markdown: ни `#`, ни `**`, ни `- ` в начале строки.
- [ ] Картинки разложены по папкам и совпадают с реальной сборкой.
- [ ] Правки внесены и в `docs/store/...`, и в `fastlane/...`.
