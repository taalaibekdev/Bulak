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
    if (value.inMinutes < 1) return '<1 мин';
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    if (hours == 0) return '$minutes мин';
    if (minutes == 0) return '$hours ч';
    return '$hours ч $minutes мин';
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference <= 0) {
      return strings.locale.languageCode == 'en' ? 'today' : 'сегодня';
    }
    if (difference == 1) {
      return strings.locale.languageCode == 'en' ? 'yesterday' : 'вчера';
    }
    if (difference < 7) {
      return strings.locale.languageCode == 'en'
          ? '$difference days ago'
          : '$difference ${AppStrings.plural(difference, 'день', 'дня', 'дней')} назад';
    }
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
