import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Работа с родительским PIN-кодом.
///
/// Сам код нигде не сохраняется: на устройстве лежит только соль и
/// SHA-256 от соли и кода. Это защищает от случайного подглядывания в
/// настройках, но не является криптографической защитой данных —
/// для детского приложения этого достаточно (см. `docs/legal/privacy-policy.ru.md`).
class PinCode {
  const PinCode._();

  /// Сколько попыток даём перед небольшой задержкой.
  static const int attemptsBeforeDelay = 5;

  /// Слишком простые коды: их легко угадать ребёнку.
  static const Set<String> weakCodes = {
    '0000',
    '1111',
    '2222',
    '3333',
    '4444',
    '5555',
    '6666',
    '7777',
    '8888',
    '9999',
    '1234',
    '4321',
    '0123',
    '1212',
    '2121',
    '1122',
    '6969',
    '1000',
    '2000',
    '1010',
  };

  /// Проверяет, что код состоит только из цифр нужной длины.
  static bool isWellFormed(String code, {int length = 4}) {
    if (code.length != length) return false;
    return RegExp(r'^\d+$').hasMatch(code);
  }

  /// Код, который легко подобрать. Такой PIN не принимаем при настройке.
  static bool isWeak(String code) => weakCodes.contains(code);

  /// Криптографически случайная соль.
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Хэш PIN-кода с солью.
  static String hash(String code, String salt) {
    final digest = sha256.convert(utf8.encode('$salt|$code|bulak'));
    return digest.toString();
  }

  /// Проверка введённого кода.
  static bool verify({
    required String code,
    required String? salt,
    required String? expectedHash,
  }) {
    if (salt == null || expectedHash == null) return false;
    if (!isWellFormed(code, length: code.length)) return false;
    return hash(code, salt) == expectedHash;
  }
}
