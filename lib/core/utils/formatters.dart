import 'package:flutter/widgets.dart';

import '../l10n/app_strings.dart';

/// Приведение чисел, времени и дат к виду, понятному ребёнку и родителю.
class Formatters {
  const Formatters._();

  /// Длительность видео: `2:05`, `12:40`, `1:02:33`.
  ///
  /// Если длительность неизвестна — пустая строка, чтобы интерфейс не
  /// показывал «null» и не занимал место.
  static String duration(Duration? value) {
    if (value == null || value <= Duration.zero) return '';
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final mm = minutes.toString().padLeft(2, '0');
      return '$hours:$mm:$ss';
    }
    return '$minutes:$ss';
  }

  /// «5 мин», «1 ч 20 мин» — для списков и лимитов.
  static String shortDuration(Duration value, AppStrings strings) {
    final units = _Units(strings.locale.languageCode);
    if (value.inMinutes < 1) return units.lessThanMinute;

    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    if (hours == 0) return '$minutes ${units.minute}';
    if (minutes == 0) return '$hours ${units.hour}';
    return '$hours ${units.hour} $minutes ${units.minute}';
  }

  /// Сколько времени ребёнок смотрит прямо сейчас: `0:42`.
  static String clock(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Процент просмотра, округлённый и ограниченный диапазоном 0–100.
  static int percent(double value) => (value.clamp(0, 1) * 100).round();

  /// Дата в виде «сегодня», «вчера», «5 октября».
  static String relativeDate(DateTime date, AppStrings strings) {
    final units = _Units(strings.locale.languageCode);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference <= 0) return units.today;
    if (difference == 1) return units.yesterday;
    if (difference < 7) return units.daysAgo(difference);

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Размер в «человеческом» виде — используется в служебных экранах.
  static String bytes(int value) {
    const units = ['Б', 'КБ', 'МБ', 'ГБ'];
    var size = value.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final digits = size >= 100 || unit == 0 ? 0 : 1;
    return '${size.toStringAsFixed(digits)} ${units[unit]}';
  }

  /// Склонение слова «видео» и подобных — обёртка над [AppStrings.plural].
  static String plural(int count, String one, String few, String many) =>
      AppStrings.plural(count, one, few, many);

  /// Безопасное получение приветствия по времени суток.
  static String greeting(AppStrings strings, {DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 5) return strings.homeGreetingEvening;
    if (hour < 12) return strings.homeGreetingMorning;
    if (hour < 18) return strings.homeGreetingDay;
    return strings.homeGreetingEvening;
  }

  /// Размер текста, который подстраивается под ширину экрана —
  /// чтобы на маленьких телефонах заголовки не «разъезжались».
  static double adaptive(BuildContext context, double base) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 340) return base * 0.86;
    if (width > 600) return base * 1.15;
    return base;
  }
}

/// Слова, которые зависят от языка, но относятся к форматированию,
/// а не к экранам: единицы времени и относительные даты.
///
/// Живут рядом с форматированием, потому что нужны в каждом списке и в
/// истории просмотра. Русские формы множественного числа считает
/// [AppStrings.plural]; в кыргызском после числительного слово не меняется,
/// поэтому там форма всегда одна.
class _Units {
  const _Units(this.code);

  final String code;

  bool get _isEn => code == 'en';
  bool get _isKy => code == 'ky';

  String get lessThanMinute => _isEn ? '<1 min' : (_isKy ? '<1 мүн' : '<1 мин');

  String get hour => _isEn ? 'h' : (_isKy ? 'саат' : 'ч');

  String get minute => _isEn ? 'min' : (_isKy ? 'мүн' : 'мин');

  String get today => _isEn ? 'today' : (_isKy ? 'бүгүн' : 'сегодня');

  String get yesterday => _isEn ? 'yesterday' : (_isKy ? 'кечээ' : 'вчера');

  String daysAgo(int days) {
    if (_isEn) return '$days days ago';
    if (_isKy) return '$days күн мурун';
    return '$days ${AppStrings.plural(days, 'день', 'дня', 'дней')} назад';
  }
}
