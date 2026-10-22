# App Store — заметки для ревьюера (App Review Notes)

Документ содержит готовый текст, который вставляется в поле **App Review Information → Notes** в App Store Connect, а также русские пояснения для команды: как подготовить ревью-сборку, что показать и как отвечать на вопросы.

Приложение: «Булак» (Bulak), Bundle ID `kg.tlbk.bulak`, версия 1.2.0.

---

## 1. Что и куда вставлять

| Поле в App Store Connect | Что указать |
|---|---|
| Sign-in required? | **No** — вход в приложение не требуется |
| Demo account | Не требуется: аккаунтов в приложении нет |
| Notes | Текст из раздела 2 ниже (на английском) |
| Contact Information | `info@mits.kg` |
| Attachment | При необходимости приложить PDF с этим документом |

**Блок для вставки в поле Notes** начинается после строки «НАЧАЛО ТЕКСТА ДЛЯ APP STORE CONNECT» и заканчивается перед строкой «КОНЕЦ ТЕКСТА ДЛЯ APP STORE CONNECT».

---

## 2. Готовый текст для App Store Connect (английский)

<!-- НАЧАЛО ТЕКСТА ДЛЯ APP STORE CONNECT -->

```
BULAK — REVIEW NOTES (v1.2.0)

WHAT THIS APP DOES

Bulak is a video player for children. There is no catalogue, no search and
no recommendations inside the app. A parent adds a video by pasting its link
and confirming with a 4-digit parental PIN. The child then sees a grid of
large cards and can watch only the videos the parent has added.

The app contains no accounts, no sign-up, no analytics, no advertising SDKs
and no trackers. All user-created data is stored only in local storage on
the device.

The app does not provide, host or distribute video content. The parent is
the only source of links, and responsibility for the added links rests with
the parent as stated in the Terms of Use.

NO SIGN-IN IS REQUIRED. There is no demo account because the app has no
accounts at all.

DOWNLOADING IS DISABLED IN THIS BUILD (MOST IMPORTANT POINT)

The build submitted for review is compiled with the download feature
disabled. In this build the download function does not exist at all: there
are no download buttons, no "Downloads" screen, no automatic downloading
and no "Preparing video" screen, and the "Downloaded only" mode is
unavailable. Because this configuration has no other way to play anything,
the app is force-switched to streaming: video is always played as a stream
from the video service, and no copies of videos are created or stored on
the device.

You can verify this directly in the app: parental mode contains no
"Downloads" section, no video card shows a download control or a
"downloaded" badge, the "Preparing video" screen never appears, and every
video starts playing straight from the network. No file is written to the
device for playback.

HOW TO PASS THE PARENTAL PIN

Parental mode is protected by a 4-digit PIN.
In this review build the PIN is:  0000

You can also set your own PIN on first launch. The PIN is stored only as an
irreversible hash in local storage; it is never transmitted anywhere.

HOW TO REVIEW THE APP IN 5 MINUTES

Child experience:
 1. Launch the app. You will see the home grid. If the grid is empty, please
    add videos first as described below.
 2. Tap any card to open the full-screen player. Playback controls are large
    and child-friendly.
 3. Tap the back control: the parental lock appears and requires the PIN
    before leaving the player.

Parent experience:
 1. Open parental mode (lock icon / settings entry).
 2. Enter 0000.
 3. Add a video by pasting a public video link, then give it a title.
 4. Optionally create a collection ("Cartoons", "Learning", "Music") and move
    the video into it.
 5. Set the daily screen-time limit to 1 minute, then watch the kind
    "That's all for today" screen appear after the limit is reached.
 6. Try "Reset everything" to confirm that all local data can be erased.
 7. Change the PIN and confirm that the old PIN no longer works.

EXAMPLE VIDEO LINKS FOR TESTING

Please use any public video link that plays in a browser. The app accepts
both full and short link formats. We will provide a few suggested public
links below before submitting; any other public link will work equally well:
<list 3-5 public video links appropriate for children here before submitting>

WHY THE APP REQUIRES A PIN FOR ADULT FEATURES

Guideline 1.3 and Guideline 5.1.4 require a parental gate before a child can
reach the open internet, external links or any adult-facing functionality.
In Bulak the following are behind the PIN: adding a video by link, renaming
and deleting videos, managing collections, setting the daily time limit,
changing the PIN, resetting data, and leaving the full-screen player.

PARENTAL GATE FOR EXTERNAL LINKS

When a video cannot be played through a direct stream (for example, the
author disabled embedding), the app opens the service's official embedded
player, loaded in privacy-enhanced mode. Access to that page requires the
parental PIN.

Inside the embedded player, navigation is restricted to the video service's
domains only. There is no address bar, no free browsing and no way to reach
an arbitrary third-party site from inside the app. The app does not launch
an external browser. Any informational link inside the app sits behind
parental mode.

WHY THE APP COMPLIES WITH THE KIDS CATEGORY REQUIREMENTS

 - No third-party analytics and no analytics that profile a child.
 - No advertising SDKs and no first-party advertising. Please note: the
   fallback embedded player may display advertising served by the video
   service itself. That advertising is not controlled by us.
 - No in-app purchases and no subscriptions.
 - No chat, comments, user-generated content or user-to-user communication.
 - No collection of personal data; see the App Privacy section, which is
   answered as "Data Not Collected" for every category.
 - A parental gate protects every path to the open internet.
 - All content is selected in advance by the parent.

THIRD-PARTY CONTENT

The app is not affiliated with, sponsored by or endorsed by any third-party
video service. In the build submitted for review, downloading is disabled
at compile time: the app does not download videos and does not store copies
of them. Playback uses the service's official mechanisms (a direct video
stream, or the official embedded player as a fallback). The app is not a
distributor of video content. Responsibility for which links are added rests
with the parent, as stated in the Terms of Use.

Thumbnails are cached locally on the device so the grid loads quickly. Video
files are never cached and never downloaded in this build: playback is
always streamed.

INTERNET CONNECTION

The app requires an internet connection to load thumbnails and video streams
from the video service. Without a connection, videos and thumbnails will not
load; the rest of the interface remains functional.

DATA AND PRIVACY

The app collects no data. The video link list, titles, collections,
favourites, viewing history, settings and the PIN hash are stored only in the
app's local storage on the device and are never transmitted to the developer.
The user can erase everything with the "Reset everything" button in parental
mode, or by deleting the app.

CONTACT

info@mits.kg
https://mits.kg/bulak
```

<!-- КОНЕЦ ТЕКСТА ДЛЯ APP STORE CONNECT -->

---

## 3. Пояснения для команды (русский)

### 3.1. Что именно проверяет ревьюер

| Что проверяется | Как «Булак» проходит проверку |
|---|---|
| Работает ли приложение без входа | Аккаунтов нет вообще: приложение полностью функционально сразу после запуска |
| Есть ли скрытые покупки и платный контент | Покупок и подписок нет, платёжных экранов нет |
| Есть ли сбор данных | App Privacy заполнен как «Data Not Collected», SDK аналитики нет |
| Есть ли реклама | Собственной рекламы нет, рекламных SDK нет |
| Есть ли parental gate | Все внешние переходы и взрослые функции закрыты PIN |
| Есть ли в отправляемой сборке скачивание видео | **Нет, если сборка сделана по чек-листу.** Проверьте на устройстве, что раздела «Загрузки», кнопок скачивания и экрана «Готовим видео» нет, а видео играет потоком. Это главный пункт заметок для ревьюера |
| Соответствуют ли скриншоты приложению | Скриншоты делаются с той же сборки, что отправляется на ревью; на них нет раздела «Загрузки», кнопок скачивания, значка «скачано» и экрана «Готовим видео» |
| Работает ли приложение без сети | Показывает понятное состояние вместо пустого экрана; видео не загружаются |

### 3.2. Подготовка ревью-сборки

1. Соберите релизную сборку **с флагом `--dart-define=BULAK_DISABLE_DOWNLOADS=true`** и **демонстрационным PIN `0000`**, затем добавьте в неё 4–6 видео, чтобы главный экран не был пустым при первом запуске. Пустой первый экран часто воспринимается ревьюером как неработающее приложение.
2. Проверьте на устройстве, что в отправляемой сборке скачивания нет: в родительском режиме отсутствует раздел «Загрузки», на карточках нет кнопок скачивания и значка «скачано», нет экрана «Готовим видео» и настройки «Откуда играть видео», а все видео играют потоком. Это самая важная проверка: именно о ней говорится в заметках для ревьюера.
3. Проверьте, что при удалении тестовых данных (через «Сбросить всё») приложение остаётся работоспособным и предлагает задать новый PIN.
4. Убедитесь, что запасной режим с официальным встроенным плеером действительно срабатывает: добавьте видео, которое обычно недоступно для встраивания, и проверьте переход.
5. Пройдите весь сценарий из раздела 2 на реальном устройстве **с интернетом** перед отправкой.
6. Заполните список примеров ссылок: ревьюер должен иметь готовые ссылки, чтобы не тратить время на поиск. Используйте только публичные ссылки; не добавляйте ссылки на закрытые, удалённые или платные видео.

> **Важно перед отправкой.** Утверждение о том, что скачивание отключено, верно только для сборки, собранной с флагом `BULAK_DISABLE_DOWNLOADS=true`. Если отправляется сборка без флага, этот абзац из заметок нужно убрать: описание не должно расходиться с фактическим поведением приложения.

### 3.3. Как заполнить список примеров ссылок

Перед отправкой замените строку `<list 3-5 public video links appropriate for children here before submitting>` на реальные ссылки. Требования к примерам:

- видео должно быть **публичным** и доступным без входа в аккаунт;
- видео должно быть **уместным для детей** (мультфильм, детская песня, обучающий ролик);
- желательно, чтобы хотя бы одно видео **не поддерживало встраивание** — так ревьюер увидит резервный режим;
- ссылки должны открываться в регионе ревьюера (проверьте доступность, если ревью проходит в США).

Рекомендуемый формат блока:

```
 1. <полная публичная ссылка>  — cartoon, embedding allowed
 2. <полная публичная ссылка>  — children's song
 3. <полная публичная ссылка>  — educational clip
 4. <короткая публичная ссылка> — short link format check
```

<!-- заполнить перед публикацией: подставить 3–5 реальных публичных ссылок на детские видео -->

### 3.4. Стратегия ответа на вопросы ревьюера

| Возможный вопрос | Рекомендуемый ответ |
|---|---|
| «Приложение использует сторонний видеосервис. Есть ли у вас разрешение?» | Содержимое добавляет сам пользователь: приложение не предоставляет каталог, поиск или рекомендации и не распространяет контент. В сборке, отправленной на ревью, скачивание отключено на этапе компиляции, поэтому копии видео не создаются. Ответственность за выбор ссылок закреплена за родителем в Пользовательском соглашении |
| «Почему в детском приложении есть доступ к внешнему сервису?» | Доступ закрыт родительским PIN-кодом и нужен только как резервный способ воспроизведения, когда прямое воспроизведение недоступно. Используется режим повышенной приватности, а навигация внутри плеера ограничена доменами сервиса. Свободного браузинга нет: открывается конкретное видео, без адресной строки. Приложение не запускает внешний браузер |
| «Показывается ли реклама детям?» | Собственной рекламы и рекламных SDK нет. Рекламу может показывать только официальный встроенный плеер сервиса, и этот режим закрыт родительским PIN-кодом |
| «Собираете ли вы данные о детях?» | Нет. Раздел App Privacy заполнен как Data Not Collected для всех категорий. Все данные хранятся локально и удаляются пользователем |
| «Что произойдёт, если родитель не добавит видео?» | Приложение покажет пустое состояние с подсказкой, как добавить видео через родительский режим. Функциональность при этом корректна |
| «Есть ли покупки?» | Нет ни покупок, ни подписок |

### 3.5. Что нельзя отправлять на ревью

| Нельзя | Почему |
|---|---|
| Сборку без флага `--dart-define=BULAK_DISABLE_DOWNLOADS=true`, если в заметках сказано об отключённом скачивании | Описание разойдётся с фактическим поведением приложения — это отдельное основание для отклонения |
| Сборку с зашитым реальным PIN родителя | Ревьюер не сможет войти в родительский режим и проверить функции |
| Сборку с пустым главным экраном | Может быть воспринята как неработающее приложение |
| Сборку без интернета на тестовом устройстве | Видео не загрузятся, ревьюер увидит неработающее приложение |
| Скриншоты, не совпадающие с интерфейсом | Отклонение по правилам о вводящих в заблуждение материалах |
| Заявления об одобрении или партнёрстве с видеосервисом | Недопустимое заявление о партнёрстве |
| Реальные ссылки на видео с сомнительным содержанием | Нарушение требований Kids Category |

### 3.6. Частые причины отклонения и как их избежать

| Причина отклонения | Профилактика |
|---|---|
| Guideline 1.3 — отсутствует или неполный parental gate | Проверить, что все внешние переходы и настройки требуют PIN |
| Guideline 2.1 — ревьюер не смог войти в функциональность | Указать демонстрационный PIN `0000` явным текстом в заметках |
| Guideline 2.3 — скрытая функциональность | Не добавлять скрытых экранов; всё, что есть, должно быть описано в заметках |
| Guideline 5.1.1 — сбор данных без раскрытия | App Privacy = Data Not Collected; в приложении нет аналитики |
| Guideline 5.2.1 — использование чужого контента | Не использовать чужие логотипы и названия в оформлении и описании |
| Guideline 5.2.3 — сохранение видео из стороннего сервиса | Отправлять только сборку с `--dart-define=BULAK_DISABLE_DOWNLOADS=true`, если в заметках заявлено об отключённом скачивании; проверить на устройстве, что раздела «Загрузки», кнопок скачивания, автоскачивания и экрана «Готовим видео» в сборке нет |
| Guideline 4.3 — недостаточная ценность | В заметках подчеркнуть уникальность: ручной отбор контента родителем, отсутствие ленты и поиска |
| Guideline 2.1 — неработающие ссылки на политику/поддержку | Проверить, что `https://mits.kg/bulak` и `https://mits.kg/privacy-policies/bulak.html` открываются публично без авторизации |

---

## 4. Чек-лист перед отправкой на ревью

- [ ] Заметки для ревьюера вставлены в App Store Connect на английском языке.
- [ ] Если в заметках сказано, что скачивание отключено, ревью-сборка действительно собрана с `--dart-define=BULAK_DISABLE_DOWNLOADS=true`.
- [ ] Проверено на устройстве: в отправляемой сборке нет раздела «Загрузки», кнопок скачивания, значка «скачано», экрана «Готовим видео» и настройки «Откуда играть видео», а видео играет потоком.
- [ ] Демонстрационный PIN `0000` указан явно и проверен на ревью-сборке.
- [ ] В сборке добавлены 4–6 тестовых видео, главный экран не пустой.
- [ ] Список 3–5 публичных ссылок заполнен вместо плейсхолдера.
- [ ] Проверено, что хотя бы одно видео демонстрирует резервный режим с встроенным плеером.
- [ ] Проверена работа без интернета: понятное сообщение вместо пустого экрана.
- [ ] Проверена кнопка «Сбросить всё».
- [ ] Проверена смена PIN-кода и блокировка выхода из плеера.
- [ ] Ссылки `https://mits.kg/bulak` и `https://mits.kg/privacy-policies/bulak.html` открываются без авторизации.
- [ ] Скриншоты совпадают с интерфейсом отправляемой сборки.
- [ ] В заметках нет названий сторонних видеосервисов и заявлений о партнёрстве с ними.
- [ ] Указан контакт `info@mits.kg`, по которому есть возможность ответить в течение суток.
