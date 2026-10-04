import 'package:flutter/material.dart';

/// Локализация приложения.
///
/// Строки держим прямо в коде, а не в ARB-файлах: языков всего два, зато
/// так перевод виден рядом с кодом, а сборка не зависит от генератора.
/// Чтобы добавить третий язык (например, кыргызский), достаточно дописать
/// ветку в [_pick] и добавить локаль в [supportedLocales].
class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = [Locale('ru'), Locale('en')];

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings(Locale('ru'));

  bool get _isEn => locale.languageCode == 'en';

  String _pick(String ru, String en) => _isEn ? en : ru;

  /// Русская форма множественного числа: 1 минута, 2 минуты, 5 минут.
  static String plural(int count, String one, String few, String many) {
    final mod100 = count % 100;
    final mod10 = count % 10;
    if (mod100 >= 11 && mod100 <= 14) return many;
    if (mod10 == 1) return one;
    if (mod10 >= 2 && mod10 <= 4) return few;
    return many;
  }

  // --- Общее -------------------------------------------------------------

  String get appName => _pick('Булак', 'Bulak');
  String get tagline => _pick(
    'Только видео, которые выбрали родители',
    'Only videos picked by parents',
  );
  String get actionCancel => _pick('Отмена', 'Cancel');
  String get actionSave => _pick('Сохранить', 'Save');
  String get actionDelete => _pick('Удалить', 'Delete');
  String get actionEdit => _pick('Изменить', 'Edit');
  String get actionAdd => _pick('Добавить', 'Add');
  String get actionDone => _pick('Готово', 'Done');
  String get actionClose => _pick('Закрыть', 'Close');
  String get actionRetry => _pick('Повторить', 'Retry');
  String get actionBack => _pick('Назад', 'Back');
  String get actionClear => _pick('Очистить', 'Clear');
  String get actionNext => _pick('Далее', 'Next');
  String get somethingWentWrong => _pick(
    'Что-то пошло не так. Попробуйте ещё раз.',
    'Something went wrong. Try again.',
  );
  String get noInternet =>
      _pick('Нет подключения к интернету', 'No internet connection');

  // --- Нижняя навигация --------------------------------------------------

  String get navHome => _pick('Главная', 'Home');
  String get navCollections => _pick('Коллекции', 'Playlists');
  String get navFavorites => _pick('Избранное', 'Favorites');
  String get navHistory => _pick('История', 'History');
  String get navParents => _pick('Родителям', 'Parents');

  // --- Главная -----------------------------------------------------------

  String get homeGreetingMorning => _pick('Доброе утро!', 'Good morning!');
  String get homeGreetingDay => _pick('Привет!', 'Hi there!');
  String get homeGreetingEvening => _pick('Добрый вечер!', 'Good evening!');
  String get homeSubtitle =>
      _pick('Что посмотрим сегодня?', 'What shall we watch today?');
  String get homeContinueWatching => _pick('Продолжить', 'Keep watching');
  String get homeAllVideos => _pick('Все видео', 'All videos');
  String get homeEmptyTitle => _pick('Здесь пока пусто', 'Nothing here yet');
  String get homeEmptyBody => _pick(
    'Попросите взрослых добавить видео: они вставят ссылку с YouTube, '
        'и оно появится на этой странице.',
    'Ask a grown-up to add a video: they paste a YouTube link and it '
        'shows up right here.',
  );
  String get homeEmptyForParent => _pick(
    'Вы родитель? Откройте раздел «Родителям» и добавьте первую ссылку.',
    'Are you a parent? Open “Parents” and add your first link.',
  );

  /// «5 видео», «1 видео».
  String videosCount(int count) =>
      _isEn ? '$count ${count == 1 ? 'video' : 'videos'}' : '$count видео';

  /// «3 коллекции», «1 коллекция», «5 коллекций».
  String collectionsCount(int count) {
    if (_isEn) return '$count ${count == 1 ? 'playlist' : 'playlists'}';
    return '$count ${plural(count, 'коллекция', 'коллекции', 'коллекций')}';
  }

  // --- Плеер -------------------------------------------------------------

  String get playerLock => _pick('Заблокировать', 'Lock');
  String get playerUnlock => _pick('Разблокировать', 'Unlock');
  String get playerExit => _pick('Выйти', 'Exit');
  String get playerLockedHint => _pick(
    'Экран заблокирован. Позовите взрослого.',
    'The screen is locked. Call a grown-up.',
  );
  String get playerUnlockTitle => _pick('PIN родителя', 'Parent PIN');
  String get playerErrorTitle =>
      _pick('Не получилось включить видео', 'Could not start the video');
  String get playerErrorBody => _pick(
    'Проверьте интернет и попробуйте ещё раз. Если не помогло — '
        'включите встроенный плеер YouTube.',
    'Check your connection and try again. If that fails, switch to the '
        'built-in YouTube player.',
  );
  String get playerUseEmbed =>
      _pick('Включить плеер YouTube', 'Use the YouTube player');
  String get playerUseDirect =>
      _pick('Вернуться к режиму без рекламы', 'Back to the ad-free mode');
  String get playerBufferring => _pick('Загружаем…', 'Loading…');
  String get playerReplay => _pick('Ещё раз', 'Watch again');
  String get playerNext => _pick('Следующее', 'Next video');
  String get playerFullscreen => _pick('Во весь экран', 'Fullscreen');
  String get playerSecondsBack => _pick('Назад', 'Back');
  String get playerSecondsForward => _pick('Вперёд', 'Forward');

  String get timeUpTitle => _pick('На сегодня всё!', 'That is all for today!');
  String get timeUpBody => _pick(
    'Мы посмотрели столько, сколько разрешили взрослые. '
        'Давайте вернёмся завтра.',
    'You have watched as much as the grown-ups allowed. '
        'See you tomorrow!',
  );
  String get timeUpButton => _pick('Хорошо', 'Okay');

  String minutesLeft(int minutes) => _isEn
      ? '$minutes min left today'
      : 'Осталось ${minutes.toString()} ${plural(minutes, 'минута', 'минуты', 'минут')}';

  // --- Коллекции ---------------------------------------------------------

  String get collectionsTitle => _pick('Коллекции', 'Playlists');
  String get collectionsEmptyTitle =>
      _pick('Коллекций пока нет', 'No playlists yet');
  String get collectionsEmptyBody => _pick(
    'Соберите видео в папки: «Мультики», «Учёба», «Музыка» — '
        'так ребёнку проще выбирать.',
    'Group videos into folders like “Cartoons”, “Learning” or “Music” — '
        'it makes choosing easier.',
  );
  String get collectionNew => _pick('Новая коллекция', 'New playlist');
  String get collectionEdit => _pick('Изменить коллекцию', 'Edit playlist');
  String get collectionNameLabel => _pick('Название', 'Name');
  String get collectionNameHint =>
      _pick('Например, «Мультики»', 'For example “Cartoons”');
  String get collectionEmojiLabel => _pick('Значок', 'Icon');
  String get collectionColorLabel => _pick('Цвет', 'Colour');
  String get collectionDeleteTitle =>
      _pick('Удалить коллекцию?', 'Delete playlist?');
  String get collectionDeleteBody => _pick(
    'Видео останутся в библиотеке, но папка исчезнет.',
    'The videos stay in your library, only the folder disappears.',
  );
  String get collectionNameRequired =>
      _pick('Введите название', 'Enter a name');

  // --- Избранное ---------------------------------------------------------

  String get favoritesTitle => _pick('Избранное', 'Favorites');
  String get favoritesEmptyTitle =>
      _pick('Здесь пока пусто', 'Nothing saved yet');
  String get favoritesEmptyBody => _pick(
    'Нажмите на сердечко рядом с видео — и оно появится здесь.',
    'Tap the heart next to a video and it will appear here.',
  );
  String get favoriteAdded =>
      _pick('Добавлено в избранное', 'Saved to favorites');
  String get favoriteRemoved =>
      _pick('Убрано из избранного', 'Removed from favorites');

  // --- История -----------------------------------------------------------

  String get historyTitle => _pick('История', 'History');
  String get historyEmptyTitle =>
      _pick('Вы ещё ничего не смотрели', 'Nothing watched yet');
  String get historyEmptyBody => _pick(
    'Как только ребёнок посмотрит видео, оно появится здесь.',
    'Once your child watches a video, it will show up here.',
  );
  String get historyClear => _pick('Очистить историю', 'Clear history');
  String get historyClearTitle => _pick('Очистить историю?', 'Clear history?');
  String get historyClearBody => _pick(
    'Список просмотров будет удалён. Видео из библиотеки останутся.',
    'The list of watched videos will be removed. Your library stays.',
  );
  String get historyWatchedToEnd => _pick('Просмотрено', 'Watched');
  String watchedPercent(int percent) =>
      _isEn ? '$percent% watched' : 'Просмотрено $percent%';

  // --- Родительский режим ------------------------------------------------

  String get parentTitle => _pick('Родителям', 'Parents');
  String get parentGateTitle => _pick('Родительский режим', 'Parent mode');
  String get parentGateBody =>
      _pick('Введите PIN-код, чтобы продолжить', 'Enter your PIN to continue');
  String get parentGateWrong =>
      _pick('Неверный PIN-код. Попробуйте ещё раз.', 'Wrong PIN. Try again.');
  String get parentSetupTitle => _pick('Придумайте PIN-код', 'Create a PIN');
  String get parentSetupBody => _pick(
    'Четыре цифры, которые знаете только вы. PIN защищает добавление '
        'видео и настройки приложения.',
    'Four digits only you know. The PIN protects adding videos and the '
        'app settings.',
  );
  String get parentSetupRepeat => _pick('Повторите PIN-код', 'Repeat the PIN');
  String get parentSetupMismatch =>
      _pick('PIN-коды не совпали', 'The PINs do not match');
  String get parentSetupTrivial => _pick(
    'Такой PIN-код слишком простой. Выберите другой.',
    'This PIN is too easy. Please pick another one.',
  );
  String get parentAddVideo => _pick('Добавить видео', 'Add a video');
  String get parentAddVideoSubtitle =>
      _pick('Вставьте ссылку с YouTube', 'Paste a YouTube link');
  String get parentMyVideos => _pick('Мои видео', 'My videos');
  String get parentMyVideosSubtitle =>
      _pick('Изменить, перенести, удалить', 'Edit, move, delete');
  String get parentCollectionsSubtitle =>
      _pick('Папки с мультиками и уроками', 'Folders for cartoons and lessons');
  String get parentTimeLimit => _pick('Лимит времени', 'Screen time');
  String get parentTimeLimitSubtitle =>
      _pick('Сколько можно смотреть в день', 'How much watching per day');
  String get parentSecurity => _pick('Безопасность', 'Security');
  String get parentSecuritySubtitle =>
      _pick('PIN-код и блокировка плеера', 'PIN and player lock');
  String get parentAppearance =>
      _pick('Внешний вид и язык', 'Look and language');
  String get parentAppearanceSubtitle =>
      _pick('Тема оформления и язык приложения', 'Theme and app language');
  String get parentAbout => _pick('О приложении', 'About');
  String get parentExit =>
      _pick('Выйти из режима родителей', 'Leave parent mode');
  String get parentLocked =>
      _pick('Режим родителей закрыт', 'Parent mode locked');
  String get parentHello => _pick('Здравствуйте!', 'Hello!');
  String get parentHelloBody => _pick(
    'Здесь настраивается всё, что видит ребёнок.',
    'Everything your child sees is set up here.',
  );

  // --- Добавление видео --------------------------------------------------

  String get addVideoTitle => _pick('Добавить видео', 'Add a video');
  String get addVideoHint =>
      _pick('Вставьте ссылку на YouTube', 'Paste a YouTube link');
  String get addVideoPaste => _pick('Вставить', 'Paste');
  String get addVideoCheck => _pick('Проверить ссылку', 'Check the link');
  String get addVideoFetching =>
      _pick('Получаем название видео…', 'Fetching the video title…');
  String get addVideoInvalid => _pick(
    'Это не похоже на ссылку YouTube. Скопируйте ссылку из приложения '
        'YouTube или из браузера.',
    'This does not look like a YouTube link. Copy it from the YouTube app '
        'or a browser.',
  );
  String get addVideoDuplicate =>
      _pick('Такое видео уже есть в библиотеке', 'This video is already saved');
  String get addVideoManyHint => _pick(
    'Можно вставить сразу несколько ссылок — по одной в строке.',
    'You can paste several links at once — one per line.',
  );
  String get addVideoTitleLabel =>
      _pick('Название для ребёнка', 'Title your child will see');
  String get addVideoTitleHint => _pick(
    'Оставьте пустым — возьмём из YouTube',
    'Leave empty to use YouTube’s',
  );
  String get addVideoCollectionLabel => _pick('Коллекция', 'Playlist');
  String get addVideoNoCollection => _pick('Без коллекции', 'No playlist');
  String get addVideoMissingTitle => _pick(
    'Не удалось получить название. Введите его вручную.',
    'Could not fetch the title. Please type it in.',
  );
  String addVideoAdded(int count) => _isEn
      ? 'Added: $count'
      : 'Добавлено ${count.toString()} ${plural(count, 'видео', 'видео', 'видео')}';
  String addVideoSkipped(int count) =>
      _isEn ? 'Skipped duplicates: $count' : 'Пропущено повторов: $count';
  String get addVideoLimitReached => _pick(
    'Библиотека заполнена. Удалите что-нибудь, чтобы добавить новое.',
    'The library is full. Remove something to add more.',
  );
  String get addVideoPreview =>
      _pick('Так увидит ребёнок', 'How your child sees it');

  // --- Управление видео --------------------------------------------------

  String get manageVideosTitle => _pick('Мои видео', 'My videos');
  String get manageVideosEmpty => _pick(
    'Библиотека пуста. Добавьте первое видео по ссылке.',
    'Your library is empty. Add the first video by link.',
  );
  String get editVideoTitle => _pick('Изменить видео', 'Edit video');
  String get deleteVideoTitle => _pick('Удалить видео?', 'Delete this video?');
  String get deleteVideoBody => _pick(
    'Оно исчезнет из библиотеки, коллекций и истории.',
    'It will disappear from the library, playlists and history.',
  );
  String get moveToCollection =>
      _pick('Перенести в коллекцию', 'Move to playlist');
  String get videoRemoved => _pick('Видео удалено', 'Video deleted');
  String get videoSaved => _pick('Изменения сохранены', 'Changes saved');
  String get manageVideosSearch =>
      _pick('Поиск по названию', 'Search by title');

  // --- Лимит времени -----------------------------------------------------

  String get timeLimitTitle => _pick('Лимит времени', 'Screen time');
  String get timeLimitUnlimited => _pick('Без ограничений', 'No limit');
  String timeLimitMinutes(int minutes) => _isEn
      ? '$minutes minutes a day'
      : '$minutes ${plural(minutes, 'минута', 'минуты', 'минут')} в день';

  /// Короткая подпись «30 мин» / «30 min» — для кнопок и счётчиков.
  String minutesShort(int minutes) => _isEn ? '$minutes min' : '$minutes мин';
  String get timeLimitTodayUsed =>
      _pick('Сегодня просмотрено', 'Watched today');
  String get timeLimitResetToday =>
      _pick('Сбросить счётчик на сегодня', 'Reset today’s counter');
  String get timeLimitReset => _pick('Счётчик сброшен', 'Counter reset');
  String get timeLimitNote => _pick(
    'Время считается только тогда, когда на экране идёт видео.',
    'Time is counted only while a video is actually playing.',
  );
  String get timeLimitExhausted => _pick(
    'Лимит на сегодня уже исчерпан',
    'Today’s limit is already used up',
  );

  // --- Безопасность ------------------------------------------------------

  String get securityTitle => _pick('Безопасность', 'Security');
  String get securityChangePin => _pick('Сменить PIN-код', 'Change PIN');
  String get securityCurrentPin => _pick('Текущий PIN-код', 'Current PIN');
  String get securityNewPin => _pick('Новый PIN-код', 'New PIN');
  String get securityPinChanged => _pick('PIN-код изменён', 'PIN changed');
  String get securityKidLock =>
      _pick('Замочек в плеере', 'Lock inside the player');
  String get securityKidLockBody => _pick(
    'В плеере появится кнопка-замочек: ребёнок не сможет выйти или '
        'перемотать видео без PIN-кода.',
    'A lock button appears in the player: your child cannot exit or seek '
        'without the PIN.',
  );
  String get securityHideFavorites =>
      _pick('Показывать избранное', 'Show favorites');
  String get securityHideHistory => _pick('Показывать историю', 'Show history');

  // --- Внешний вид -------------------------------------------------------

  String get appearanceTitle =>
      _pick('Внешний вид и язык', 'Look and language');
  String get appearanceTheme => _pick('Тема оформления', 'Theme');
  String get themeSystem => _pick('Как в системе', 'System');
  String get themeLight => _pick('Светлая', 'Light');
  String get themeDark => _pick('Тёмная', 'Dark');
  String get appearanceLanguage => _pick('Язык приложения', 'App language');
  String get languageSystem => _pick('Как в системе', 'System');
  String get languageRussian => 'Русский';
  String get languageEnglish => 'English';
  String get playbackTitle => _pick('Режим воспроизведения', 'Playback mode');
  String get playbackAuto => _pick('Автоматически', 'Automatic');
  String get playbackDirect => _pick('Без рекламы YouTube', 'Ad-free stream');
  String get playbackEmbed => _pick('Плеер YouTube', 'YouTube player');
  String get playbackNote => _pick(
    'В режиме «Без рекламы» видео играет без интерфейса YouTube, но '
        'качество ограничено 360p. В режиме «Плеер YouTube» показывается '
        'официальный плеер — качество выше, но YouTube может показать '
        'свою рекламу.',
    'In the ad-free mode the video plays without YouTube’s interface, but '
        'quality is capped at 360p. The YouTube player gives you higher '
        'quality and may show YouTube’s own ads.',
  );

  // --- О приложении ------------------------------------------------------

  String get aboutTitle => _pick('О приложении', 'About');
  String get aboutVersion => _pick('Версия', 'Version');
  String get aboutPrivacy =>
      _pick('Политика конфиденциальности', 'Privacy policy');
  String get aboutTerms => _pick('Условия использования', 'Terms of use');
  String get aboutSupport => _pick('Написать в поддержку', 'Contact support');
  String get aboutDataTitle => _pick('Ваши данные', 'Your data');
  String get aboutDataBody => _pick(
    'Всё, что вы добавляете, хранится только на этом устройстве. '
        'Мы не собираем персональные данные, не ставим аналитику и не '
        'показываем собственную рекламу.',
    'Everything you add stays on this device. We collect no personal '
        'data, use no analytics and show no ads of our own.',
  );
  String get aboutYouTubeNotice => _pick(
    'Видео загружаются с YouTube. YouTube — товарный знак Google LLC. '
        'Приложение не связано с Google и не одобрено ею.',
    'Videos are streamed from YouTube. YouTube is a trademark of Google '
        'LLC. This app is not affiliated with or endorsed by Google.',
  );
  String get aboutReset => _pick('Удалить все данные', 'Delete all data');
  String get aboutResetTitle =>
      _pick('Удалить все данные?', 'Delete all data?');
  String get aboutResetBody => _pick(
    'Будут удалены все добавленные видео, коллекции, история и настройки, '
        'включая PIN-код. Действие нельзя отменить.',
    'All videos, playlists, history and settings — including the PIN — '
        'will be erased. This cannot be undone.',
  );
  String get aboutResetDone => _pick('Все данные удалены', 'All data deleted');

  // --- Первый запуск -----------------------------------------------------

  String get onboardTitle =>
      _pick('Добро пожаловать в «Булак»!', 'Welcome to Bulak!');
  String get onboardBody => _pick(
    'Это видеоплеер, в котором нет ничего лишнего: ребёнок видит только '
        'те видео, которые вы добавите сами.',
    'A video player without the noise: your child sees only the videos '
        'you add yourself.',
  );
  String get onboardBullet1 => _pick(
    'Никаких рекомендаций и бесконечной ленты',
    'No recommendations, no endless feed',
  );
  String get onboardBullet2 => _pick(
    'Добавление видео защищено PIN-кодом',
    'Adding videos is protected by a PIN',
  );
  String get onboardBullet3 =>
      _pick('Лимит времени на просмотр в день', 'A daily screen-time limit');
  String get onboardStart => _pick('Начать настройку', 'Start setup');
  String get onboardPinStep => _pick('Шаг 1 из 2', 'Step 1 of 2');
  String get onboardAddStep => _pick('Шаг 2 из 2', 'Step 2 of 2');
  String get onboardPinDone => _pick('PIN-код сохранён', 'PIN saved');
  String get onboardAddVideoTitle =>
      _pick('Добавьте первое видео', 'Add your first video');
  String get onboardSkipAdd => _pick('Пропустить', 'Skip for now');
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => AppStrings.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
