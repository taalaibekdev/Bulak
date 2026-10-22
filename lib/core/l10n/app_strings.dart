import 'package:flutter/material.dart';

/// Локализация приложения.
///
/// Строки держим прямо в коде, а не в ARB-файлах: языков всего три, зато
/// так перевод виден рядом с кодом, а сборка не зависит от генератора.
///
/// Порядок аргументов в [_pick] — русский, английский, кыргызский.
/// Кыргызский необязателен: если перевода ещё нет, показываем русский,
/// чтобы в интерфейсе не было пустых надписей.
class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  /// Основной язык приложения — кыргызский.
  static const Locale defaultLocale = Locale('ky');

  static const List<Locale> supportedLocales = [
    Locale('ky'),
    Locale('ru'),
    Locale('en'),
  ];

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings(defaultLocale);

  bool get _isKy => locale.languageCode == 'ky';
  bool get _isEn => locale.languageCode == 'en';

  String _pick(String ru, String en, [String? ky]) {
    if (_isEn) return en;
    if (_isKy) return ky ?? ru;
    return ru;
  }

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

  String get appName => _pick('Булак', 'Bulak', 'Булак');
  String get tagline => _pick(
    'Только видео, которые выбрали родители',
    'Only videos picked by parents',
    'Ата-эне тандаган видеолор гана',
  );
  String get actionCancel => _pick('Отмена', 'Cancel', 'Жокко чыгаруу');
  String get actionSave => _pick('Сохранить', 'Save', 'Сактоо');
  String get actionDelete => _pick('Удалить', 'Delete', 'Өчүрүү');
  String get actionEdit => _pick('Изменить', 'Edit', 'Өзгөртүү');
  String get actionAdd => _pick('Добавить', 'Add', 'Кошуу');
  String get actionDone => _pick('Готово', 'Done', 'Бүттү');
  String get actionClose => _pick('Закрыть', 'Close', 'Жабуу');
  String get actionRetry => _pick('Повторить', 'Retry', 'Кайталоо');
  String get actionBack => _pick('Назад', 'Back', 'Артка');
  String get actionClear => _pick('Очистить', 'Clear', 'Тазалоо');
  String get actionNext => _pick('Далее', 'Next', 'Кийинки');
  String get somethingWentWrong => _pick(
    'Что-то пошло не так. Попробуйте ещё раз.',
    'Something went wrong. Try again.',
    'Бир нерсе туура эмес болду. Кайра аракет кылыңыз.',
  );
  String get noInternet => _pick(
    'Нет подключения к интернету',
    'No internet connection',
    'Интернет жок',
  );

  // --- Нижняя навигация --------------------------------------------------

  String get navHome => _pick('Главная', 'Home', 'Башкы бет');
  String get navCollections => _pick('Коллекции', 'Playlists', 'Топтомдор');
  String get navFavorites => _pick('Избранное', 'Favorites', 'Сүйүктүүлөр');
  String get navHistory => _pick('История', 'History', 'Тарых');
  String get navParents => _pick('Родителям', 'Parents', 'Ата-энелерге');

  // --- Главная -----------------------------------------------------------

  String get homeGreetingMorning =>
      _pick('Доброе утро!', 'Good morning!', 'Кутман таң!');
  String get homeGreetingDay => _pick('Привет!', 'Hi there!', 'Салам!');
  String get homeGreetingEvening =>
      _pick('Добрый вечер!', 'Good evening!', 'Кутман кеч!');
  String get homeSubtitle => _pick(
    'Что посмотрим сегодня?',
    'What shall we watch today?',
    'Бүгүн эмне көрөбүз?',
  );
  String get homeContinueWatching =>
      _pick('Продолжить', 'Keep watching', 'Улантуу');
  String get homeAllVideos => _pick('Все видео', 'All videos', 'Бардык видео');
  String get homeEmptyTitle =>
      _pick('Здесь пока пусто', 'Nothing here yet', 'Азырынча бош');
  String get homeEmptyBody => _pick(
    'Попросите взрослых добавить видео: они вставят ссылку на видео, '
        'и оно появится на этой странице.',
    'Ask a grown-up to add a video: they paste a video link and it '
        'shows up right here.',
    'Чоңдордон видео кошуусун сураңыз: алар шилтеме коюшат, '
        'ошондо видео ушул жерде пайда болот.',
  );
  String get homeEmptyForParent => _pick(
    'Вы родитель? Откройте раздел «Родителям» и добавьте первую ссылку.',
    'Are you a parent? Open “Parents” and add your first link.',
    'Сиз ата-энесизби? «Ата-энелерге» бөлүмүн ачып, биринчи шилтемени кошуңуз.',
  );

  /// «5 видео», «1 видео». В кыргызском форма слова не меняется.
  String videosCount(int count) {
    if (_isEn) return '$count ${count == 1 ? 'video' : 'videos'}';
    if (_isKy) return '$count видео';
    return '$count видео';
  }

  /// «3 коллекции», «1 коллекция», «5 коллекций».
  /// В кыргызском после числительного слово не меняется: «3 топтом».
  String collectionsCount(int count) {
    if (_isEn) return '$count ${count == 1 ? 'playlist' : 'playlists'}';
    if (_isKy) return '$count топтом';
    return '$count ${plural(count, 'коллекция', 'коллекции', 'коллекций')}';
  }

  // --- Скачивание на устройство ------------------------------------------

  String get downloadsTitle => _pick('Загрузки', 'Downloads', 'Жүктөлгөндөр');
  String get downloadsSubtitle => _pick(
    'Скачанные видео играют без интернета',
    'Downloaded videos play without internet',
    'Жүктөлгөн видеолор интернетсиз ойнойт',
  );
  String get downloadAction => _pick('Скачать', 'Download', 'Жүктөө');
  String get downloadAllAction =>
      _pick('Скачать все', 'Download all', 'Баарын жүктөө');
  String get downloadRemove =>
      _pick('Удалить загрузку', 'Delete download', 'Жүктөөнү өчүрүү');
  String get downloadRemoveAll => _pick(
    'Удалить все загрузки',
    'Delete all downloads',
    'Бардык жүктөөлөрдү өчүрүү',
  );
  String get downloadCancelled => _pick(
    'Загрузка отменена',
    'Download cancelled',
    'Жүктөө жокко чыгарылды',
  );
  String get downloadFailed => _pick(
    'Не удалось скачать видео. Проверьте интернет и попробуйте снова.',
    'Could not download the video. Check your connection and try again.',
    'Видео жүктөлбөдү. Интернетти текшерип, дагы бир жолу аракет кылыңыз.',
  );
  String get downloadDone =>
      _pick('Видео скачано', 'Video downloaded', 'Видео жүктөлдү');
  String downloadQueued(int count) {
    if (_isEn) return '$count in the download queue';
    if (_isKy) return 'Жүктөө кезегинде: $count';
    return 'В очереди на скачивание: $count';
  }

  String get downloadInProgress =>
      _pick('Скачиваем…', 'Downloading…', 'Жүктөп жатабыз…');
  String get downloadPlaying =>
      _pick('Играет без интернета', 'Plays offline', 'Интернетсиз ойнойт');
  String get downloadBadge => _pick('Скачано', 'Saved', 'Жүктөлдү');
  String get downloadStorageTitle => _pick(
    'Занято на устройстве',
    'Used on this device',
    'Түзмөктө ээлеген орун',
  );
  String get downloadEmpty => _pick(
    'Скачанных видео пока нет. Нажмите «Скачать» у видео — оно сохранится '
        'на устройстве и будет играть без интернета.',
    'No downloaded videos yet. Tap Download next to a video to save it on '
        'this device so it plays without internet.',
    'Азырынча жүктөлгөн видео жок. Видеонун жанындагы «Жүктөө» баскычын '
        'басыңыз — ал түзмөккө сакталып, интернетсиз ойнойт.',
  );
  String get downloadAutoTitle => _pick(
    'Скачивать сразу при добавлении',
    'Download right after adding',
    'Кошкондо дароо жүктөө',
  );
  String get downloadAutoBody => _pick(
    'Как только вы добавите ссылку, приложение само сохранит видео '
        'на устройстве.',
    'As soon as you add a link, the app saves the video on this device.',
    'Шилтемени кошконуңуз менен, колдонмо видеону өзү түзмөккө сактайт.',
  );
  String get downloadPreferLocalTitle => _pick(
    'Играть сохранённое видео',
    'Play the saved copy',
    'Сакталган видеону ойнотуу',
  );
  String get downloadPreferLocalBody => _pick(
    'Если видео скачано, плеер берёт файл с устройства — так просмотр '
        'не прерывается.',
    'If a video is downloaded, the player uses the local file so playback '
        'never stalls.',
    'Эгер видео жүктөлгөн болсо, плеер түзмөктөгү файлды алат — '
        'ошентип көрүү үзүлбөйт.',
  );
  String get downloadLegalNote => _pick(
    'Скачивание сохраняет видео на этот телефон. Используйте функцию для '
        'личного просмотра и не передавайте скачанные файлы другим: это '
        'может нарушать права авторов видео.',
    'Downloading saves the video to this phone. Use it for personal viewing '
        'and do not pass downloaded files to others: that may infringe the '
        'rights of the video authors.',
    'Жүктөө видеону ушул телефонго сактайт. Бул функцияны жеке көрүү үчүн '
        'колдонуңуз жана жүктөлгөн файлдарды башкаларга бербеңиз: мындай '
        'кылуу видеонун авторлорунун укуктарын бузушу мүмкүн.',
  );
  String get downloadSizeUnknown =>
      _pick('размер неизвестен', 'size unknown', 'көлөмү белгисиз');
  String get downloadWifiHint => _pick(
    'Скачивание расходует интернет-трафик. Лучше делать это по Wi-Fi.',
    'Downloading uses mobile data. Wi-Fi is recommended.',
    'Жүктөө интернет-трафикти коротот. Wi-Fi аркылуу жүктөгөн жакшы.',
  );

  // --- Обмен подборками --------------------------------------------------

  String get shareTitle =>
      _pick('Обмен подборками', 'Share playlists', 'Топтомдорду бөлүшүү');
  String get shareSubtitle => _pick(
    'Отправьте список ссылок другому родителю',
    'Send a list of links to another parent',
    'Шилтемелердин тизмесин башка ата-энеге жөнөтүңүз',
  );
  String get shareExportSection => _pick('Поделиться', 'Share', 'Бөлүшүү');
  String get shareExportAll =>
      _pick('Вся библиотека', 'Whole library', 'Бардык китепкана');
  String get shareExportCollection => _pick('Коллекция', 'Playlist', 'Топтом');
  String get shareExportAsText =>
      _pick('Отправить ссылками', 'Send as links', 'Шилтеме менен жөнөтүү');
  String get shareExportAsFile =>
      _pick('Отправить файлом', 'Send as a file', 'Файл менен жөнөтүү');
  String get shareExportHint => _pick(
    'Получатель вставит этот список в приложении «Булак» и скачает те же '
        'видео себе.',
    'The other person pastes this list into Bulak and downloads the same '
        'videos.',
    'Алуучу бул тизмени «Булак» колдонмосуна чаптап, ошол эле видеолорду '
        'өзүнө жүктөп алат.',
  );
  String get shareExportEmpty => _pick(
    'В библиотеке пока нет видео',
    'There are no videos yet',
    'Китепканада азырынча видео жок',
  );
  String get shareCopied => _pick('Скопировано', 'Copied', 'Көчүрүлдү');
  String get shareImportSection =>
      _pick('Получить подборку', 'Import a list', 'Топтомду алуу');
  String get shareImportHint => _pick(
    'Вставьте список ссылок или файл подборки',
    'Paste a list of links or a playlist file',
    'Шилтемелердин тизмесин же топтомдун файлын чаптаңыз',
  );
  String get shareImportPaste => _pick('Вставить', 'Paste', 'Чаптоо');
  String get shareImportCheck => _pick('Проверить', 'Check', 'Текшерүү');
  String get shareImportInvalid => _pick(
    'Здесь нет ссылок на видео. Проверьте, что скопировали всё сообщение '
        'или файл целиком.',
    'No video links found. Make sure you copied the whole message or file.',
    'Бул жерде видеого шилтеме жок. Бүт билдирүүнү же файлды толук '
        'көчүргөнүңүздү текшериңиз.',
  );
  String shareImportFound(int count) {
    if (_isEn) return 'Found: $count';
    if (_isKy) return 'Табылды: $count';
    return 'Найдено: $count';
  }

  String shareImportNew(int count) {
    if (_isEn) return 'New: $count';
    if (_isKy) return 'Жаңы: $count';
    return 'Новых: $count';
  }

  String shareImportDuplicates(int count) {
    if (_isEn) return 'Already in the library: $count';
    if (_isKy) return 'Китепканада бар: $count';
    return 'Уже есть в библиотеке: $count';
  }

  String get shareImportTargetNew =>
      _pick('Создать коллекцию', 'Create a playlist', 'Топтом түзүү');
  String get shareImportTargetExisting => _pick(
    'В существующую коллекцию',
    'Into an existing playlist',
    'Бар топтомго',
  );
  String get shareImportTargetNone =>
      _pick('Без коллекции', 'No playlist', 'Топтомсуз');
  String get shareImportAction =>
      _pick('Добавить в библиотеку', 'Add to library', 'Китепканага кошуу');
  String get shareImportTitleLabel =>
      _pick('Название коллекции', 'Playlist name', 'Топтомдун аталышы');
  String shareImportDone(int count) {
    if (_isEn) return 'Added: $count';
    if (_isKy) return 'Кошулган видео: $count';
    return 'Добавлено видео: $count';
  }

  String get shareImportDownloadAfter => _pick(
    'Скачать добавленные видео',
    'Download the added videos',
    'Кошулган видеолорду жүктөө',
  );
  String get shareImportNothingNew => _pick(
    'Новых видео нет — всё уже в библиотеке',
    'Nothing new to add',
    'Жаңы видео жок — баары китепканада',
  );

  // --- Плеер -------------------------------------------------------------

  String get playerLock => _pick('Заблокировать', 'Lock', 'Кулпулоо');
  String get playerUnlock => _pick('Разблокировать', 'Unlock', 'Кулпуну ачуу');
  String get playerExit => _pick('Выйти', 'Exit', 'Чыгуу');
  String get playerLockedHint => _pick(
    'Экран заблокирован. Позовите взрослого.',
    'The screen is locked. Call a grown-up.',
    'Экран кулпуланган. Чоң кишини чакырыңыз.',
  );

  /// Подсказка, если замок нажали коротко: он включается удержанием.
  String get playerLockHoldHint => _pick(
    'Чтобы заблокировать плеер, удерживайте замочек',
    'Hold the lock icon to lock the player',
    'Плеерди кулпулоо үчүн кулпуну басып кармаңыз',
  );
  String get playerLockConfirmTitle => _pick(
    'Заблокировать плеер?',
    'Lock the player?',
    'Плеерди кулпулайбызбы?',
  );
  String get playerLockConfirmBody => _pick(
    'Плеер перестанет закрываться и перематываться. Снять замок можно только PIN-кодом.',
    'The player will stop closing and seeking. Only a PIN can unlock it.',
    'Плеер жабылбайт жана оролбойт. Кулпуну PIN-код менен гана ачат.',
  );
  String get playerUnlockTitle =>
      _pick('PIN родителя', 'Parent PIN', 'Ата-эненин PIN-коду');
  String get playerErrorTitle => _pick(
    'Не получилось включить видео',
    'Could not start the video',
    'Видео күйгүзүлбөдү',
  );
  String get playerErrorBody => _pick(
    'Проверьте интернет и попробуйте ещё раз. Если не помогло — '
        'включите встроенный плеер.',
    'Check your connection and try again. If that fails, switch to the '
        'built-in player.',
    'Интернетти текшерип, дагы бир жолу аракет кылыңыз. Жардам бербесе — '
        'курулган плеерди күйгүзүңүз.',
  );
  String get playerUseEmbed => _pick(
    'Включить встроенный плеер',
    'Use the built-in player',
    'Курулган плеерди күйгүзүү',
  );
  String get playerUseDirect => _pick(
    'Вернуться к режиму без рекламы',
    'Back to the ad-free mode',
    'Жарнамасыз режимге кайтуу',
  );
  String get playerBufferring =>
      _pick('Загружаем…', 'Loading…', 'Жүктөп жатабыз…');
  String get playerReplay => _pick('Ещё раз', 'Watch again', 'Дагы бир жолу');
  String get playerNext => _pick('Следующее', 'Next video', 'Кийинки видео');
  String get playerFullscreen =>
      _pick('Во весь экран', 'Fullscreen', 'Бүт экранга');

  /// Экран подготовки: видео сначала скачивается, потом играет.
  String get prepareTitle =>
      _pick('Готовим видео', 'Getting it ready', 'Видео даярдалып жатат');
  String get prepareBody => _pick(
    'Скачиваем видео на телефон — потом оно будет играть из памяти '
        'устройства, без интернета.',
    'Downloading the video to this phone — after that it plays from local '
        'storage, without internet.',
    'Видео телефонго жүктөлүп жатат — кийин ал түзмөктүн эс тутумунан, '
        'интернетсиз ойнойт.',
  );
  String get prepareWaitingForQueue =>
      _pick('Ждём очередь…', 'Waiting in the queue…', 'Кезек күтүп жатабыз…');
  String get prepareCancel => _pick('Отменить', 'Cancel', 'Жокко чыгаруу');
  String get prepareFailedTitle => _pick(
    'Не удалось скачать видео',
    'Could not download the video',
    'Видео жүктөлбөдү',
  );
  String get prepareFailedBody => _pick(
    'Проверьте интернет и попробуйте ещё раз.',
    'Check your connection and try again.',
    'Интернетти текшерип, дагы бир жолу аракет кылыңыз.',
  );
  String get prepareRetry =>
      _pick('Попробовать снова', 'Try again', 'Кайра аракет кылуу');
  String get prepareAlmostDone =>
      _pick('Почти готово…', 'Almost done…', 'Дээрлик бүттү…');
  String get prepareReady =>
      _pick('Готово! Включаем', 'Ready! Starting', 'Бүттү! Баштайбыз');
  String get playerNotDownloaded => _pick(
    'Видео ещё не скачано',
    'Video is not downloaded yet',
    'Видео азырынча жүктөлө элек',
  );

  // --- Источник воспроизведения ------------------------------------------

  String get playbackSourceTitle => _pick(
    'Откуда играть видео',
    'Where to play from',
    'Видеону кайдан ойнотуу',
  );
  String get playbackSourceDownloaded =>
      _pick('Только скачанное', 'Downloaded only', 'Жүктөлгөндөр гана');
  String get playbackSourceDownloadedBody => _pick(
    'Видео сначала сохраняется на телефон и только потом играет. '
        'Просмотр не зависит от интернета и не обрывается.',
    'The video is saved to this phone first and only then plays. Playback '
        'does not depend on the internet and never stalls.',
    'Видео адегенде телефонго сакталат, анан гана ойнойт. Көрүү интернетке '
        'көз каранды эмес жана үзүлбөйт.',
  );
  String get playbackSourceStream => _pick(
    'Потоком, если не скачано',
    'Stream when not downloaded',
    'Жүктөлбөсө, агым менен',
  );
  String get playbackSourceStreamBody => _pick(
    'Если файла нет, видео играет сразу из сети. Так быстрее начать, но '
        'просмотр может прерваться.',
    'If there is no file, the video streams right away. It starts faster, '
        'but playback may stall.',
    'Эгер файл жок болсо, видео түз эле тармактан ойнойт. Баштоо тезирээк, '
        'бирок көрүү үзүлүшү мүмкүн.',
  );
  String get playerSecondsBack => _pick('Назад', 'Back', 'Артка');
  String get playerSecondsForward => _pick('Вперёд', 'Forward', 'Алдыга');

  String get timeUpTitle =>
      _pick('На сегодня всё!', 'That is all for today!', 'Бүгүнкүсү бүттү!');
  String get timeUpBody => _pick(
    'Мы посмотрели столько, сколько разрешили взрослые. '
        'Давайте вернёмся завтра.',
    'You have watched as much as the grown-ups allowed. '
        'See you tomorrow!',
    'Чоңдор уруксат кылганча көрдүк. Эртең дагы көрөбүз.',
  );
  String get timeUpButton => _pick('Хорошо', 'Okay', 'Жарайт');

  /// «Осталось 5 минут». В кыргызском слово после числа не меняется.
  String minutesLeft(int minutes) {
    if (_isEn) return '$minutes min left today';
    if (_isKy) return '$minutes мүнөт калды';
    return 'Осталось ${minutes.toString()} ${plural(minutes, 'минута', 'минуты', 'минут')}';
  }

  // --- Коллекции ---------------------------------------------------------

  String get collectionsTitle => _pick('Коллекции', 'Playlists', 'Топтомдор');
  String get collectionsEmptyTitle =>
      _pick('Коллекций пока нет', 'No playlists yet', 'Азырынча топтом жок');
  String get collectionsEmptyBody => _pick(
    'Соберите видео в папки: «Мультики», «Учёба», «Музыка» — '
        'так ребёнку проще выбирать.',
    'Group videos into folders like “Cartoons”, “Learning” or “Music” — '
        'it makes choosing easier.',
    'Видеолорду «Мультфильмдер», «Окуу», «Музыка» деген папкаларга '
        'чогултуңуз — балага тандоо оңой болот.',
  );
  String get collectionNew =>
      _pick('Новая коллекция', 'New playlist', 'Жаңы топтом');
  String get collectionEdit =>
      _pick('Изменить коллекцию', 'Edit playlist', 'Топтомду өзгөртүү');
  String get collectionNameLabel => _pick('Название', 'Name', 'Аталышы');
  String get collectionNameHint => _pick(
    'Например, «Мультики»',
    'For example “Cartoons”',
    'Мисалы, «Мультфильмдер»',
  );
  String get collectionEmojiLabel => _pick('Значок', 'Icon', 'Белги');
  String get collectionColorLabel => _pick('Цвет', 'Colour', 'Түс');
  String get collectionDeleteTitle =>
      _pick('Удалить коллекцию?', 'Delete playlist?', 'Топтомду өчүрөсүзбү?');
  String get collectionDeleteBody => _pick(
    'Видео останутся в библиотеке, но папка исчезнет.',
    'The videos stay in your library, only the folder disappears.',
    'Видеолор китепканада калат, папка гана жоголот.',
  );
  String get collectionNameRequired =>
      _pick('Введите название', 'Enter a name', 'Аталышын жазыңыз');

  // --- Избранное ---------------------------------------------------------

  String get favoritesTitle => _pick('Избранное', 'Favorites', 'Сүйүктүүлөр');
  String get favoritesEmptyTitle =>
      _pick('Здесь пока пусто', 'Nothing saved yet', 'Азырынча бош');
  String get favoritesEmptyBody => _pick(
    'Нажмите на сердечко рядом с видео — и оно появится здесь.',
    'Tap the heart next to a video and it will appear here.',
    'Видеонун жанындагы жүрөкчөнү басыңыз — ал ушул жерде пайда болот.',
  );
  String get favoriteAdded => _pick(
    'Добавлено в избранное',
    'Saved to favorites',
    'Сүйүктүүлөргө кошулду',
  );
  String get favoriteRemoved => _pick(
    'Убрано из избранного',
    'Removed from favorites',
    'Сүйүктүүлөрдөн алынды',
  );

  // --- История -----------------------------------------------------------

  String get historyTitle => _pick('История', 'History', 'Тарых');
  String get historyEmptyTitle => _pick(
    'Вы ещё ничего не смотрели',
    'Nothing watched yet',
    'Сиз азырынча эч нерсе көрө элексиз',
  );
  String get historyEmptyBody => _pick(
    'Как только ребёнок посмотрит видео, оно появится здесь.',
    'Once your child watches a video, it will show up here.',
    'Бала видео көргөн замат ал ушул жерде пайда болот.',
  );
  String get historyClear =>
      _pick('Очистить историю', 'Clear history', 'Тарыхты тазалоо');
  String get historyClearTitle =>
      _pick('Очистить историю?', 'Clear history?', 'Тарыхты тазалайсызбы?');
  String get historyClearBody => _pick(
    'Список просмотров будет удалён. Видео из библиотеки останутся.',
    'The list of watched videos will be removed. Your library stays.',
    'Көрүүлөрдүн тизмеси өчүрүлөт. Китепканадагы видеолор калат.',
  );
  String get historyWatchedToEnd => _pick('Просмотрено', 'Watched', 'Көрүлдү');
  String watchedPercent(int percent) {
    if (_isEn) return '$percent% watched';
    if (_isKy) return 'Көрүлдү $percent%';
    return 'Просмотрено $percent%';
  }

  // --- Родительский режим ------------------------------------------------

  String get parentTitle => _pick('Родителям', 'Parents', 'Ата-энелерге');
  String get parentGateTitle =>
      _pick('Родительский режим', 'Parent mode', 'Ата-эне режими');
  String get parentGateBody => _pick(
    'Введите PIN-код, чтобы продолжить',
    'Enter your PIN to continue',
    'Улантуу үчүн PIN-кодду киргизиңиз',
  );
  String get parentGateWrong => _pick(
    'Неверный PIN-код. Попробуйте ещё раз.',
    'Wrong PIN. Try again.',
    'PIN-код туура эмес. Дагы бир жолу аракет кылыңыз.',
  );
  String get parentSetupTitle =>
      _pick('Придумайте PIN-код', 'Create a PIN', 'PIN-код ойлоп табыңыз');
  String get parentSetupBody => _pick(
    'Четыре цифры, которые знаете только вы. PIN защищает добавление '
        'видео и настройки приложения.',
    'Four digits only you know. The PIN protects adding videos and the '
        'app settings.',
    'Сиз гана билген төрт сан. PIN видео кошууну жана колдонмонун '
        'жөндөөлөрүн коргойт.',
  );
  String get parentSetupRepeat =>
      _pick('Повторите PIN-код', 'Repeat the PIN', 'PIN-кодду кайталаңыз');
  String get parentSetupMismatch => _pick(
    'PIN-коды не совпали',
    'The PINs do not match',
    'PIN-коддор дал келбеди',
  );
  String get parentSetupTrivial => _pick(
    'Такой PIN-код слишком простой. Выберите другой.',
    'This PIN is too easy. Please pick another one.',
    'Мындай PIN-код өтө жөнөкөй. Башкасын тандаңыз.',
  );
  String get parentAddVideo =>
      _pick('Добавить видео', 'Add a video', 'Видео кошуу');
  String get parentAddVideoSubtitle => _pick(
    'Вставьте ссылку на видео',
    'Paste a video link',
    'Шилтеме чаптаңыз',
  );
  String get parentMyVideos =>
      _pick('Мои видео', 'My videos', 'Менин видеолорум');
  String get parentMyVideosSubtitle => _pick(
    'Изменить, перенести, удалить',
    'Edit, move, delete',
    'Өзгөртүү, жылдыруу, өчүрүү',
  );
  String get parentCollectionsSubtitle => _pick(
    'Папки с мультиками и уроками',
    'Folders for cartoons and lessons',
    'Мультфильм жана сабактар салынган папкалар',
  );
  String get parentTimeLimit =>
      _pick('Лимит времени', 'Screen time', 'Убакыт чеги');
  String get parentTimeLimitSubtitle => _pick(
    'Сколько можно смотреть в день',
    'How much watching per day',
    'Күнүнө канча көрүүгө болот',
  );
  String get parentSecurity => _pick('Безопасность', 'Security', 'Коопсуздук');
  String get parentSecuritySubtitle => _pick(
    'PIN-код и блокировка плеера',
    'PIN and player lock',
    'PIN-код жана плеерди кулпулоо',
  );
  String get parentAppearance =>
      _pick('Внешний вид и язык', 'Look and language', 'Көрүнүш жана тил');
  String get parentAppearanceSubtitle => _pick(
    'Тема оформления и язык приложения',
    'Theme and app language',
    'Колдонмонун темасы жана тили',
  );
  String get parentAbout => _pick('О приложении', 'About', 'Колдонмо жөнүндө');
  String get parentExit => _pick(
    'Выйти из режима родителей',
    'Leave parent mode',
    'Ата-эне режиминен чыгуу',
  );
  String get parentLocked => _pick(
    'Режим родителей закрыт',
    'Parent mode locked',
    'Ата-эне режими жабык',
  );
  String get parentHello => _pick('Здравствуйте!', 'Hello!', 'Саламсызбы!');
  String get parentHelloBody => _pick(
    'Здесь настраивается всё, что видит ребёнок.',
    'Everything your child sees is set up here.',
    'Бул жерде бала көргөн нерсенин баары жөндөлөт.',
  );

  // --- Добавление видео --------------------------------------------------

  String get addVideoTitle =>
      _pick('Добавить видео', 'Add a video', 'Видео кошуу');
  String get addVideoHint => _pick(
    'Вставьте ссылку на видео',
    'Paste a video link',
    'Шилтеме чаптаңыз',
  );
  String get addVideoPaste => _pick('Вставить', 'Paste', 'Чаптоо');
  String get addVideoCheck =>
      _pick('Проверить ссылку', 'Check the link', 'Шилтемени текшерүү');
  String get addVideoFetching => _pick(
    'Получаем название видео…',
    'Fetching the video title…',
    'Видеонун аталышын алып жатабыз…',
  );
  String get addVideoInvalid => _pick(
    'Это не похоже на ссылку на видео. Скопируйте ссылку из приложения, '
        'где вы смотрите видео, или из браузера.',
    'This does not look like a video link. Copy it from the app where you '
        'watch videos or from a browser.',
    'Бул шилтемеге окшобойт. Шилтемени видео көргөн колдонмодон же '
        'браузерден көчүрүңүз.',
  );
  String get addVideoDuplicate => _pick(
    'Такое видео уже есть в библиотеке',
    'This video is already saved',
    'Мындай видео китепканада мурунтан бар',
  );
  String get addVideoManyHint => _pick(
    'Можно вставить сразу несколько ссылок — по одной в строке.',
    'You can paste several links at once — one per line.',
    'Бирден бир нече шилтемени чаптасаңыз болот — ар бири өзүнчө сапта.',
  );
  String get addVideoTitleLabel => _pick(
    'Название для ребёнка',
    'Title your child will see',
    'Бала көрө турган аталыш',
  );
  String get addVideoTitleHint => _pick(
    'Оставьте пустым — название подставим сами',
    'Leave empty and we will fill it in',
    'Бош калтырсаңыз — аталышын өзүбүз алабыз',
  );
  String get addVideoCollectionLabel =>
      _pick('Коллекция', 'Playlist', 'Топтом');
  String get addVideoNoCollection =>
      _pick('Без коллекции', 'No playlist', 'Топтомсуз');
  String get addVideoMissingTitle => _pick(
    'Не удалось получить название. Введите его вручную.',
    'Could not fetch the title. Please type it in.',
    'Аталышын алуу мүмкүн болбоду. Аны кол менен жазыңыз.',
  );
  String addVideoAdded(int count) {
    if (_isEn) return 'Added: $count';
    if (_isKy) return '$count видео кошулду';
    return 'Добавлено ${count.toString()} ${plural(count, 'видео', 'видео', 'видео')}';
  }

  String addVideoSkipped(int count) {
    if (_isEn) return 'Skipped duplicates: $count';
    if (_isKy) return 'Кайталангандар өткөрүлдү: $count';
    return 'Пропущено повторов: $count';
  }

  String get addVideoLimitReached => _pick(
    'Библиотека заполнена. Удалите что-нибудь, чтобы добавить новое.',
    'The library is full. Remove something to add more.',
    'Китепкана толду. Жаңы кошуу үчүн бир нерсени өчүрүңүз.',
  );
  String get addVideoPreview => _pick(
    'Так увидит ребёнок',
    'How your child sees it',
    'Бала ушундай көрөт',
  );

  // --- Управление видео --------------------------------------------------

  String get manageVideosTitle =>
      _pick('Мои видео', 'My videos', 'Менин видеолорум');
  String get manageVideosEmpty => _pick(
    'Библиотека пуста. Добавьте первое видео по ссылке.',
    'Your library is empty. Add the first video by link.',
    'Китепкана бош. Шилтеме аркылуу биринчи видеону кошуңуз.',
  );
  String get editVideoTitle =>
      _pick('Изменить видео', 'Edit video', 'Видеону өзгөртүү');
  String get deleteVideoTitle =>
      _pick('Удалить видео?', 'Delete this video?', 'Видеону өчүрөсүзбү?');
  String get deleteVideoBody => _pick(
    'Оно исчезнет из библиотеки, коллекций и истории.',
    'It will disappear from the library, playlists and history.',
    'Ал китепканадан, топтомдордон жана тарыхтан жоголот.',
  );
  String get moveToCollection =>
      _pick('Перенести в коллекцию', 'Move to playlist', 'Топтомго жылдыруу');
  String get videoRemoved =>
      _pick('Видео удалено', 'Video deleted', 'Видео өчүрүлдү');
  String get videoSaved =>
      _pick('Изменения сохранены', 'Changes saved', 'Өзгөртүүлөр сакталды');
  String get manageVideosSearch =>
      _pick('Поиск по названию', 'Search by title', 'Аталышы боюнча издөө');

  // --- Лимит времени -----------------------------------------------------

  String get timeLimitTitle =>
      _pick('Лимит времени', 'Screen time', 'Убакыт чеги');
  String get timeLimitUnlimited =>
      _pick('Без ограничений', 'No limit', 'Чектөөсүз');
  String timeLimitMinutes(int minutes) {
    if (_isEn) return '$minutes minutes a day';
    if (_isKy) return '$minutes мүнөт күнүнө';
    return '$minutes ${plural(minutes, 'минута', 'минуты', 'минут')} в день';
  }

  /// Короткая подпись «30 мин» / «30 min» / «30 мүнөт» — для кнопок и счётчиков.
  String minutesShort(int minutes) {
    if (_isEn) return '$minutes min';
    if (_isKy) return '$minutes мүнөт';
    return '$minutes мин';
  }

  String get timeLimitTodayUsed =>
      _pick('Сегодня просмотрено', 'Watched today', 'Бүгүн көрүлдү');
  String get timeLimitResetToday => _pick(
    'Сбросить счётчик на сегодня',
    'Reset today’s counter',
    'Бүгүнкү эсепти тазалоо',
  );
  String get timeLimitReset =>
      _pick('Счётчик сброшен', 'Counter reset', 'Эсеп тазаланды');
  String get timeLimitNote => _pick(
    'Время считается только тогда, когда на экране идёт видео.',
    'Time is counted only while a video is actually playing.',
    'Убакыт экранда видео жүргөндө гана эсептелет.',
  );
  String get timeLimitExhausted => _pick(
    'Лимит на сегодня уже исчерпан',
    'Today’s limit is already used up',
    'Бүгүнкү чек бүтүп калды',
  );

  // --- Безопасность ------------------------------------------------------

  String get securityTitle => _pick('Безопасность', 'Security', 'Коопсуздук');
  String get securityChangePin =>
      _pick('Сменить PIN-код', 'Change PIN', 'PIN-кодду өзгөртүү');
  String get securityCurrentPin =>
      _pick('Текущий PIN-код', 'Current PIN', 'Азыркы PIN-код');
  String get securityNewPin =>
      _pick('Новый PIN-код', 'New PIN', 'Жаңы PIN-код');
  String get securityPinChanged =>
      _pick('PIN-код изменён', 'PIN changed', 'PIN-код өзгөртүлдү');
  String get securityKidLock =>
      _pick('Замочек в плеере', 'Lock inside the player', 'Плеердеги кулпу');
  String get securityKidLockBody => _pick(
    'В плеере появится кнопка-замочек: ребёнок не сможет выйти или '
        'перемотать видео без PIN-кода.',
    'A lock button appears in the player: your child cannot exit or seek '
        'without the PIN.',
    'Плеерде кулпу баскычы пайда болот: бала PIN-кодсуз чыга албайт же '
        'видеону ордунан жылдыра албайт.',
  );
  String get securityHideFavorites =>
      _pick('Показывать избранное', 'Show favorites', 'Сүйүктүүлөрдү көрсөтүү');
  String get securityHideHistory =>
      _pick('Показывать историю', 'Show history', 'Тарыхты көрсөтүү');

  // --- Внешний вид -------------------------------------------------------

  String get appearanceTitle =>
      _pick('Внешний вид и язык', 'Look and language', 'Көрүнүш жана тил');
  String get appearanceTheme => _pick('Тема оформления', 'Theme', 'Тема');
  String get themeSystem => _pick('Как в системе', 'System', 'Системадагыдай');
  String get themeLight => _pick('Светлая', 'Light', 'Жарык');
  String get themeDark => _pick('Тёмная', 'Dark', 'Караңгы');
  String get appearanceLanguage =>
      _pick('Язык приложения', 'App language', 'Колдонмонун тили');
  String get languageSystem =>
      _pick('Как в системе', 'System', 'Системадагыдай');
  String get languageSystemHint => _pick(
    'Язык, выбранный в настройках телефона. Если он нам не знаком — кыргызский.',
    'The language set on the phone. If we do not support it — Kyrgyz.',
    'Телефондун жөндөөлөрүндө тандалган тил. Ал бизде жок болсо — кыргызча.',
  );
  String get languageKyrgyzHint => _pick(
    'Основной язык приложения.',
    'The app’s main language.',
    'Колдонмонун негизги тили.',
  );
  String get languageKyrgyz => 'Кыргызча';
  String get languageRussian => 'Русский';
  String get languageEnglish => 'English';
  String get playbackTitle =>
      _pick('Режим воспроизведения', 'Playback mode', 'Ойнотуу режими');
  String get playbackAuto => _pick('Автоматически', 'Automatic', 'Автоматтык');
  String get playbackDirect =>
      _pick('Без рекламы', 'Ad-free', 'Жарнамасыз');
  String get playbackEmbed =>
      _pick('Встроенный плеер', 'Built-in player', 'Курулган плеер');
  String get playbackNote => _pick(
    'В режиме «Без рекламы» видео играет без интерфейса сервиса, но '
        'качество ограничено 360p. В режиме «Встроенный плеер» показывается '
        'официальный плеер — качество выше, но сервис может показать '
        'свою рекламу.',
    'In the ad-free mode the video plays without the service interface, but '
        'quality is capped at 360p. The built-in player gives you higher '
        'quality and the service may show its own ads.',
    '«Жарнамасыз» режиминде видео сервистин интерфейсинсиз ойнойт, бирок '
        'сапаты 360p менен чектелген. «Курулган плеер» режиминде расмий '
        'плеер көрсөтүлөт — сапаты жогору, бирок сервис өзүнүн жарнамасын '
        'көрсөтүшү мүмкүн.',
  );

  // --- О приложении ------------------------------------------------------

  String get aboutTitle => _pick('О приложении', 'About', 'Колдонмо жөнүндө');
  String get aboutVersion => _pick('Версия', 'Version', 'Версия');
  String get aboutPrivacy => _pick(
    'Политика конфиденциальности',
    'Privacy policy',
    'Купуялык саясаты',
  );
  String get aboutTerms =>
      _pick('Условия использования', 'Terms of use', 'Колдонуу шарттары');
  String get aboutSupport => _pick(
    'Написать в поддержку',
    'Contact support',
    'Колдоо кызматына жазуу',
  );
  String get aboutDataTitle =>
      _pick('Ваши данные', 'Your data', 'Сиздин маалыматтар');
  String get aboutDataBody => _pick(
    'Всё, что вы добавляете, хранится только на этом устройстве. '
        'Мы не собираем персональные данные, не ставим аналитику и не '
        'показываем собственную рекламу.',
    'Everything you add stays on this device. We collect no personal '
        'data, use no analytics and show no ads of our own.',
    'Сиз кошкон нерсенин баары ушул түзмөктө гана сакталат. Биз жеке '
        'маалыматтарды чогултпайбыз, аналитика колдонбойбуз жана '
        'өзүбүздүн жарнамабызды көрсөтпөйбүз.',
  );
  String get aboutSourceTitle => _pick(
    'Источник видео',
    'Video source',
    'Видео булагы',
  );
  String get aboutSourceNotice => _pick(
    'Видео воспроизводятся из внешнего видеосервиса по ссылке, которую '
        'добавил родитель. Приложение не связано с этим сервисом, '
        'не спонсируется и не одобрено им.',
    'Videos are played from an external video service by a link the parent '
        'added. This app is not affiliated with that service, is not '
        'sponsored by it and is not endorsed by it.',
    'Видеолор ата-эне кошкон шилтеме боюнча сырткы видео кызматынан '
        'ойнотулат. Колдонмо бул кызмат менен байланышпайт, аны менен '
        'каржыланбайт жана ал тарабынан жактырылган эмес.',
  );
  String get aboutReset => _pick(
    'Удалить все данные',
    'Delete all data',
    'Бардык маалыматты өчүрүү',
  );
  String get aboutResetTitle => _pick(
    'Удалить все данные?',
    'Delete all data?',
    'Бардык маалыматты өчүрөсүзбү?',
  );
  String get aboutResetBody => _pick(
    'Будут удалены все добавленные видео, коллекции, история и настройки, '
        'включая PIN-код. Действие нельзя отменить.',
    'All videos, playlists, history and settings — including the PIN — '
        'will be erased. This cannot be undone.',
    'Кошулган бардык видеолор, топтомдор, тарых жана жөндөөлөр, анын '
        'ичинде PIN-код өчүрүлөт. Бул аракетти артка кайтаруу мүмкүн эмес.',
  );
  String get aboutResetDone => _pick(
    'Все данные удалены',
    'All data deleted',
    'Бардык маалымат өчүрүлдү',
  );

  // --- Первый запуск -----------------------------------------------------

  String get onboardTitle => _pick(
    'Добро пожаловать в «Булак»!',
    'Welcome to Bulak!',
    '«Булак» колдонмосуна кош келиңиз!',
  );
  String get onboardBody => _pick(
    'Это видеоплеер, в котором нет ничего лишнего: ребёнок видит только '
        'те видео, которые вы добавите сами.',
    'A video player without the noise: your child sees only the videos '
        'you add yourself.',
    'Бул ашыкча нерсеси жок видеоплеер: бала сиз өзүңүз кошкон '
        'видеолорду гана көрөт.',
  );
  String get onboardBullet1 => _pick(
    'Никаких рекомендаций и бесконечной ленты',
    'No recommendations, no endless feed',
    'Эч кандай сунуштар жана чексиз тасма жок',
  );
  String get onboardBullet2 => _pick(
    'Добавление видео защищено PIN-кодом',
    'Adding videos is protected by a PIN',
    'Видео кошуу PIN-код менен корголгон',
  );
  String get onboardBullet3 => _pick(
    'Лимит времени на просмотр в день',
    'A daily screen-time limit',
    'Күнүнө көрүү үчүн убакыт чеги',
  );
  String get onboardStart =>
      _pick('Начать настройку', 'Start setup', 'Жөндөөнү баштоо');
  String get onboardPinStep =>
      _pick('Шаг 1 из 2', 'Step 1 of 2', '2ден 1-кадам');
  String get onboardAddStep =>
      _pick('Шаг 2 из 2', 'Step 2 of 2', '2ден 2-кадам');
  String get onboardPinDone =>
      _pick('PIN-код сохранён', 'PIN saved', 'PIN-код сакталды');
  String get onboardAddVideoTitle => _pick(
    'Добавьте первое видео',
    'Add your first video',
    'Биринчи видеону кошуңуз',
  );
  String get onboardSkipAdd =>
      _pick('Пропустить', 'Skip for now', 'Өткөрүп жиберүү');
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
