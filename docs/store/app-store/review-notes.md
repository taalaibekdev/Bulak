# App Store — заметки для ревьюера (App Review Notes)

Документ содержит готовый текст, который вставляется в поле **App Review Information → Notes** в App Store Connect, а также русские пояснения для команды: как подготовить ревью-сборку, что показать и как отвечать на вопросы.

Приложение: «Булак» (Bulak), Bundle ID `kg.tlbk.bulak`, версия 1.0.0 (build 1).

---

## 1. Что и куда вставлять

| Поле в App Store Connect | Что указать |
|---|---|
| Sign-in required? | **No** — вход в приложение не требуется |
| Demo account | Не требуется: аккаунтов в приложении нет |
| Notes | Текст из раздела 2 ниже (на английском) |
| Contact Information | `support@tlbk.kg` |
| Attachment | При необходимости приложить PDF с этим документом |

**Блок для вставки в поле Notes** начинается после строки «НАЧАЛО ТЕКСТА ДЛЯ APP STORE CONNECT» и заканчивается перед строкой «КОНЕЦ ТЕКСТА ДЛЯ APP STORE CONNECT».

---

## 2. Готовый текст для App Store Connect (английский)

<!-- НАЧАЛО ТЕКСТА ДЛЯ APP STORE CONNECT -->

```
BULAK — REVIEW NOTES (v1.0.0, build 1)

WHAT THIS APP DOES

Bulak is a video player for children. There is no catalogue, no search and
no recommendations inside the app. A parent finds a video on YouTube, copies
its link and saves it in the app after entering a 4-digit parental PIN. The
child then sees a grid of large cards and can watch only the videos the
parent has selected.

The app contains no accounts, no sign-up, no analytics, no advertising SDKs
and no trackers. All user-created data is stored only in local storage on
the device.

NO SIGN-IN IS REQUIRED. There is no demo account because the app has no
accounts at all.

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
 3. Add a video by pasting a YouTube link, then give it a title.
 4. Optionally create a collection ("Cartoons", "Learning", "Music") and move
    the video into it.
 5. Set the daily screen-time limit to 1 minute, then watch the kind
    "That's all for today" screen appear after the limit is reached.
 6. Try "Reset everything" to confirm that all local data can be erased.
 7. Change the PIN and confirm that the old PIN no longer works.

EXAMPLE VIDEO LINKS FOR TESTING

Please use any public YouTube video link. The app accepts standard link
formats such as:
    https://www.youtube.com/watch?v=XXXXXXXXXXX
    https://youtu.be/XXXXXXXXXXX
    https://m.youtube.com/watch?v=XXXXXXXXXXX

We have listed a few suggested public links below that are appropriate for
testing. Any other public YouTube link will work equally well:
<list 3-5 public YouTube links appropriate for children here before submitting>

WHY THE APP REQUIRES A PIN FOR ADULT FEATURES

Guideline 1.3 and Guideline 5.1.4 require a parental gate before a child can
reach the open internet, external links or any adult-facing functionality.
In Bulak the following are behind the PIN: adding a video by link, renaming
and deleting videos, managing collections, setting the daily time limit,
changing the PIN, resetting data, opening the fallback youtube.com page, and
leaving the full-screen player.

PARENTAL GATE FOR EXTERNAL LINKS

When a video cannot be played through a direct stream (for example, the
creator disabled embedding), the app opens the official YouTube embedded
player, loaded from the youtube-nocookie.com domain (YouTube's
privacy-enhanced mode). Access to that page requires the parental PIN.

Inside the embedded player, navigation is restricted to YouTube and Google
domains only (youtube-nocookie.com, youtube.com, ytimg.com, googlevideo.com).
There is no address bar, no free browsing and no way to reach an arbitrary
third-party site from inside the app. The app does not launch an external
browser. Any informational link inside the app sits behind parental mode.

WHY THE APP COMPLIES WITH THE KIDS CATEGORY REQUIREMENTS

 - No third-party analytics and no analytics that profile a child.
 - No advertising SDKs and no first-party advertising. Please note: the
   fallback embedded YouTube player may display advertising served by YouTube
   itself. That advertising is Google's and is not controlled by us.
 - No in-app purchases and no subscriptions.
 - No chat, comments, user-generated content or user-to-user communication.
 - No collection of personal data; see the App Privacy section, which is
   answered as "Data Not Collected" for every category.
 - A parental gate protects every path to the open internet.
 - All content is selected in advance by the parent.

ABOUT YOUTUBE AND THIRD-PARTY CONTENT

YouTube is a trademark of Google LLC. Bulak is not affiliated with, sponsored
by or endorsed by Google. The app does not download videos and does not store
copies of them: playback uses official YouTube mechanisms (a direct video
stream, or the official embedded YouTube player loaded from
youtube-nocookie.com as a fallback). The app is not a distributor of video
content. Responsibility for which links are added rests with the parent, as
stated in the Terms of Use.

Thumbnails are cached locally on the device so the grid loads quickly. Video
files are never cached: playback is always streamed.

INTERNET CONNECTION

The app requires an internet connection to load thumbnails and video streams
from YouTube servers. Without a connection, videos and thumbnails will not
load; the rest of the interface remains functional.

DATA AND PRIVACY

The app collects no data. The video link list, titles, collections,
favourites, viewing history, settings and the PIN hash are stored only in the
app's local storage on the device and are never transmitted to the developer.
The user can erase everything with the "Reset everything" button in parental
mode, or by deleting the app.

CONTACT

support@tlbk.kg
https://bulak.tlbk.kg
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
| Соответствуют ли скриншоты приложению | Скриншоты делаются с той же сборки, что отправляется на ревью |
| Работает ли приложение без сети | Показывает понятное состояние вместо пустого экрана; видео не загружаются |

### 3.2. Подготовка ревью-сборки

1. Соберите релизную сборку с **демонстрационным PIN `0000`** и добавьте в неё 4–6 видео, чтобы главный экран не был пустым при первом запуске. Пустой первый экран часто воспринимается ревьюером как неработающее приложение.
2. Проверьте, что при удалении тестовых данных (через «Сбросить всё») приложение остаётся работоспособным и предлагает задать новый PIN.
3. Убедитесь, что запасной режим с официальным встроенным плеером YouTube действительно срабатывает: добавьте видео, которое обычно недоступно для встраивания, и проверьте переход.
4. Пройдите весь сценарий из раздела 2 на реальном устройстве **с интернетом** перед отправкой.
5. Заполните список примеров ссылок: ревьюер должен иметь готовые ссылки, чтобы не тратить время на поиск. Используйте только публичные ссылки; не добавляйте ссылки на закрытые, удалённые или платные видео.

### 3.3. Как заполнить список примеров ссылок

Перед отправкой замените строку `<list 3-5 public YouTube links appropriate for children here before submitting>` на реальные ссылки. Требования к примерам:

- видео должно быть **публичным** и доступным без входа в аккаунт Google;
- видео должно быть **уместным для детей** (мультфильм, детская песня, обучающий ролик);
- желательно, чтобы хотя бы одно видео **не поддерживало встраивание** — так ревьюер увидит резервный режим;
- ссылки должны открываться в регионе ревьюера (проверьте доступность, если ревью проходит в США).

Рекомендуемый формат блока:

```
 1. https://www.youtube.com/watch?v=<ID_1>  — cartoon, embedding allowed
 2. https://www.youtube.com/watch?v=<ID_2>  — children's song
 3. https://www.youtube.com/watch?v=<ID_3>  — educational clip
 4. https://youtu.be/<ID_4>                  — short link format check
```

<!-- заполнить перед публикацией: подставить 3–5 реальных публичных ссылок на детские видео вместо <ID_N> -->

### 3.4. Стратегия ответа на вопросы ревьюера

| Возможный вопрос | Рекомендуемый ответ |
|---|---|
| «Приложение использует YouTube. Есть ли у вас разрешение?» | Приложение не скачивает и не хранит копии видео, не является распространителем контента. Воспроизведение выполняется через официальные механизмы YouTube. Ответственность за выбор ссылок закреплена за родителем в Пользовательском соглашении |
| «Почему в детском приложении есть доступ к youtube.com?» | Доступ закрыт родительским PIN-кодом и нужен только как резервный способ воспроизведения, когда прямое воспроизведение недоступно. Используется домен `youtube-nocookie.com` (режим повышенной приватности), а навигация внутри плеера ограничена доменами YouTube и Google. Свободного браузинга нет: открывается конкретное видео, без адресной строки. Приложение не запускает внешний браузер |
| «Показывается ли реклама детям?» | Собственной рекламы и рекламных SDK нет. Рекламу может показывать только официальный встроенный плеер YouTube, и этот режим закрыт родительским PIN-кодом |
| «Собираете ли вы данные о детях?» | Нет. Раздел App Privacy заполнен как Data Not Collected для всех категорий. Все данные хранятся локально и удаляются пользователем |
| «Что произойдёт, если родитель не добавит видео?» | Приложение покажет пустое состояние с подсказкой, как добавить видео через родительский режим. Функциональность при этом корректна |
| «Есть ли покупки?» | Нет ни покупок, ни подписок |

### 3.5. Что нельзя отправлять на ревью

| Нельзя | Почему |
|---|---|
| Сборку с зашитым реальным PIN родителя | Ревьюер не сможет войти в родительский режим и проверить функции |
| Сборку с пустым главным экраном | Может быть воспринята как неработающее приложение |
| Сборку без интернета на тестовом устройстве | Видео не загрузятся, ревьюер увидит неработающее приложение |
| Скриншоты, не совпадающие с интерфейсом | Отклонение по правилам о вводящих в заблуждение материалах |
| Упоминание в тексте заметок «одобрено YouTube» | Недопустимое заявление о партнёрстве с Google |
| Реальные ссылки на видео с сомнительным содержанием | Нарушение требований Kids Category |

### 3.6. Частые причины отклонения и как их избежать

| Причина отклонения | Профилактика |
|---|---|
| Guideline 1.3 — отсутствует или неполный parental gate | Проверить, что все внешние переходы и настройки требуют PIN |
| Guideline 2.1 — ревьюер не смог войти в функциональность | Указать демонстрационный PIN `0000` явным текстом в заметках |
| Guideline 2.3 — скрытая функциональность | Не добавлять скрытых экранов; всё, что есть, должно быть описано в заметках |
| Guideline 5.1.1 — сбор данных без раскрытия | App Privacy = Data Not Collected; в приложении нет аналитики |
| Guideline 5.2.1 — использование чужого контента | Никаких логотипов YouTube, дисклеймер об отсутствии связи с Google |
| Guideline 4.3 — недостаточная ценность | В заметках подчеркнуть уникальность: ручной отбор контента родителем, отсутствие ленты и поиска |
| Guideline 2.1 — неработающие ссылки на политику/поддержку | Проверить, что `https://bulak.tlbk.kg` и `https://bulak.tlbk.kg/privacy` открываются публично без авторизации |

---

## 4. Чек-лист перед отправкой на ревью

- [ ] Заметки для ревьюера вставлены в App Store Connect на английском языке.
- [ ] Демонстрационный PIN `0000` указан явно и проверен на ревью-сборке.
- [ ] В сборке добавлены 4–6 тестовых видео, главный экран не пустой.
- [ ] Список 3–5 публичных ссылок заполнен вместо плейсхолдера.
- [ ] Проверено, что хотя бы одно видео демонстрирует резервный режим с встроенным плеером YouTube.
- [ ] Проверена работа без интернета: понятное сообщение вместо пустого экрана.
- [ ] Проверена кнопка «Сбросить всё».
- [ ] Проверена смена PIN-кода и блокировка выхода из плеера.
- [ ] Ссылки `https://bulak.tlbk.kg` и `https://bulak.tlbk.kg/privacy` открываются без авторизации.
- [ ] Скриншоты совпадают с интерфейсом отправляемой сборки.
- [ ] В заметках нет утверждений о партнёрстве с Google или YouTube.
- [ ] Указан контакт `support@tlbk.kg`, по которому есть возможность ответить в течение суток.
