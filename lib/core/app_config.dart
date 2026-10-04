/// Постоянные сведения о приложении и внешние ссылки.
///
/// Значения держим в одном месте, чтобы они не расползались по коду и
/// совпадали с тем, что указано в сторах (см. `docs/store`).
library;

class AppConfig {
  const AppConfig._();

  /// Короткое имя бренда (латиницей) — используется в технических текстах.
  static const String brandName = 'Bulak';

  /// Отображаемое имя приложения, оно же label на домашнем экране.
  static const String displayName = 'Булак';

  /// Идентификатор пакета Android и bundle id iOS.
  static const String applicationId = 'kg.tlbk.bulak';

  /// Куда писать родителям.
  static const String supportEmail = 'support@tlbk.kg';

  /// Сайт приложения.
  static const String website = 'https://bulak.tlbk.kg';

  /// Политика конфиденциальности (размещается на сайте).
  static const String privacyPolicyUrl = 'https://bulak.tlbk.kg/privacy';

  /// Условия использования.
  static const String termsOfUseUrl = 'https://bulak.tlbk.kg/terms';

  /// Сколько цифр в родительском PIN-коде.
  static const int pinLength = 4;

  /// Демонстрационный PIN для ревьюеров App Store и Google Play.
  /// Меняется родителем при первом запуске, значение приведено в
  /// `docs/store/app-store/review-notes.md`.
  static const String reviewDemoPin = '0000';

  /// Максимальное количество видео в локальной библиотеке.
  /// Ограничение защищает хранилище от бесконечного роста.
  static const int maxVideos = 2000;

  /// Сколько последних просмотров хранить в истории.
  static const int maxHistoryEntries = 200;
}
