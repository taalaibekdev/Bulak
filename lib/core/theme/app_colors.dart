import 'package:flutter/material.dart';

/// Палитра приложения «Булак».
///
/// Настроение: свежая вода, солнце и мультики. Цвета подобраны так, чтобы
/// интерфейс оставался ярким для ребёнка, но не «кислотным» для родителя.
class AppColors {
  const AppColors._();

  // --- Бренд -------------------------------------------------------------

  /// Светлый фирменный зелёный — начало градиента бренда.
  ///
  /// Иконка и логотип повторяют форму иконки YouTube (скруглённый квадрат
  /// с треугольником воспроизведения), но в зелёном: это спокойнее для
  /// детского приложения и не копирует чужой товарный знак.
  static const Color greenLight = Color(0xFF4ADE80);

  /// Средний фирменный зелёный.
  static const Color greenMid = Color(0xFF22C55E);

  /// Глубокий фирменный зелёный — конец градиента бренда.
  static const Color greenDark = Color(0xFF16A34A);

  /// Небесный — используется в оформлении разделов и коллекций.
  static const Color sky = Color(0xFF2AD1FF);

  /// Основной синий интерфейса: кнопки, нижнее меню, ссылки.
  static const Color blue = Color(0xFF2A6BFF);

  /// Глубокий фиолетово-синий — для декоративных градиентов.
  static const Color violet = Color(0xFF6C4BFF);

  /// Тёмная «ночная» основа: splash и тёмная тема.
  static const Color midnight = Color(0xFF0E1B3A);

  // --- Акценты -----------------------------------------------------------

  /// Солнечный — награды, избранное, прогресс.
  static const Color sunny = Color(0xFFFFC93C);

  /// Коралловый — удаление, предупреждения.
  static const Color coral = Color(0xFFFF7A59);

  /// Мятный — успех, «нравится».
  static const Color mint = Color(0xFF3ED598);

  /// Лавандовый — коллекции и декор.
  static const Color lavender = Color(0xFF9B7BFF);

  /// Розовый — декор.
  static const Color bubblegum = Color(0xFFFF7BB8);

  // --- Светлая тема ------------------------------------------------------

  static const Color lightBackground = Color(0xFFF4F8FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEAF1FF);
  static const Color lightText = Color(0xFF10214A);
  static const Color lightTextMuted = Color(0xFF6B7A9E);

  // --- Тёмная тема -------------------------------------------------------

  static const Color darkBackground = Color(0xFF0B1430);
  static const Color darkSurface = Color(0xFF16244A);
  static const Color darkSurfaceAlt = Color(0xFF1F3160);
  static const Color darkText = Color(0xFFF2F6FF);
  static const Color darkTextMuted = Color(0xFF9FB0D6);

  // --- Градиенты ---------------------------------------------------------

  /// Основной градиент бренда: зелёный, как у иконки приложения.
  /// Используется для логотипа и декоративных кругов без текста.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [greenLight, greenMid, greenDark],
  );

  /// Тёмный зелёный градиент для поверхностей с белым текстом.
  ///
  /// Светлый фирменный зелёный не даёт нужного контраста с белым, поэтому
  /// там, где на плашке есть подписи, берём эти тона.
  static const LinearGradient brandGradientDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
  );

  /// Фон первого экрана: синий градиент, на котором зелёный логотип
  /// хорошо читается.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sky, blue, violet],
  );

  /// Тёплый градиент для «плюсовых» действий.
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunny, coral],
  );

  /// Набор градиентов для карточек коллекций. Родитель выбирает цвет
  /// по индексу, поэтому список должен быть стабильным — не менять порядок.
  static const List<List<Color>> collectionGradients = [
    [Color(0xFF2AD1FF), Color(0xFF2A6BFF)], // небо
    [Color(0xFF6C4BFF), Color(0xFFB05BFF)], // фиолет
    [Color(0xFFFF7BB8), Color(0xFFFF5C8A)], // розовый
    [Color(0xFF3ED598), Color(0xFF1FA97A)], // мята
    [Color(0xFFFFC93C), Color(0xFFFF8A3C)], // солнце
    [Color(0xFFFF7A59), Color(0xFFE8452F)], // коралл
    [Color(0xFF46C0FF), Color(0xFF3ED598)], // лагуна
    [Color(0xFF8A7BFF), Color(0xFF5B4BFF)], // индиго
  ];

  /// Градиент коллекции по индексу (с защитой от выхода за границы).
  static List<Color> collectionGradient(int index) =>
      collectionGradients[index % collectionGradients.length];

  /// Эмодзи, которые предлагаются родителю при создании коллекции.
  static const List<String> collectionEmojis = [
    '🎬',
    '🧸',
    '🚀',
    '🐣',
    '🎨',
    '📚',
    '🎵',
    '🐾',
    '⚽',
    '🌍',
    '🔬',
    '🧩',
    '🍎',
    '🌈',
    '⭐',
    '🚂',
  ];
}
