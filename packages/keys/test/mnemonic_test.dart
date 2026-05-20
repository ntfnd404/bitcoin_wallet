import 'package:keys/keys.dart' show Mnemonic;
import 'package:test/test.dart';

void main() {
  group('Mnemonic', () {
    test('toString does not expose mnemonic words', () {
      final mnemonic = Mnemonic(words: List.filled(12, 'abandon'));

      final output = mnemonic.toString();

      expect(output, isNot(contains('abandon')));
      expect(output, contains('<redacted>'));
    });
  });
}
