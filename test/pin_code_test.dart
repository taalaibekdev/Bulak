import 'package:bulak/core/utils/pin_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PinCode', () {
    test('хэш детерминирован для одной соли', () {
      const salt = 'test-salt';
      expect(PinCode.hash('1234', salt), PinCode.hash('1234', salt));
    });

    test('разные соли дают разные хэши', () {
      expect(PinCode.hash('1234', 'a'), isNot(PinCode.hash('1234', 'b')));
    });

    test('verify принимает верный код', () {
      final salt = PinCode.generateSalt();
      final hash = PinCode.hash('4821', salt);
      expect(
        PinCode.verify(code: '4821', salt: salt, expectedHash: hash),
        isTrue,
      );
    });

    test('verify отклоняет неверный код, пустые данные и отсутствие PIN', () {
      final salt = PinCode.generateSalt();
      final hash = PinCode.hash('4821', salt);
      expect(
        PinCode.verify(code: '1111', salt: salt, expectedHash: hash),
        isFalse,
      );
      expect(
        PinCode.verify(code: '4821', salt: null, expectedHash: hash),
        isFalse,
      );
      expect(
        PinCode.verify(code: '4821', salt: salt, expectedHash: null),
        isFalse,
      );
    });

    test('соль каждый раз новая', () {
      expect(PinCode.generateSalt(), isNot(PinCode.generateSalt()));
    });

    test('проверка формата кода', () {
      expect(PinCode.isWellFormed('0000'), isTrue);
      expect(PinCode.isWellFormed('123'), isFalse);
      expect(PinCode.isWellFormed('12a4'), isFalse);
      expect(PinCode.isWellFormed(''), isFalse);
    });

    test('простые коды считаются ненадёжными', () {
      expect(PinCode.isWeak('0000'), isTrue);
      expect(PinCode.isWeak('1234'), isTrue);
      expect(PinCode.isWeak('4821'), isFalse);
    });
  });
}
