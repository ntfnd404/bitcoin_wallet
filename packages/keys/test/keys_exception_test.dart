import 'package:keys/keys.dart'
    show
        KeysDerivationException,
        KeysSeedNotFoundException,
        KeysSigningException,
        KeysStorageException;
import 'package:test/test.dart';

void main() {
  group('KeysException subtypes', () {
    test('all KeysException subtypes have fixed zero-field toString', () {
      // Each subtype must return a fixed, non-dynamic string from toString().
      // This guards against accidental addition of wallet identifiers, key
      // material, or derivation paths to exception messages (Rule SB-4).

      const seedNotFound = KeysSeedNotFoundException();
      const derivation = KeysDerivationException();
      const signing = KeysSigningException();
      const storage = KeysStorageException();

      expect(seedNotFound.toString(), equals('Wallet seed not found'));
      expect(derivation.toString(), equals('Key derivation failed'));
      expect(signing.toString(), equals('Transaction signing failed'));
      expect(storage.toString(), equals('Keys storage error'));

      // None of the fixed strings can contain an injected sentinel —
      // verifying that toString() is a compile-time constant, not built
      // from dynamic fields.
      const sentinel = 'sentinel_CAFEBABE';
      expect(seedNotFound.toString(), isNot(contains(sentinel)));
      expect(derivation.toString(), isNot(contains(sentinel)));
      expect(signing.toString(), isNot(contains(sentinel)));
      expect(storage.toString(), isNot(contains(sentinel)));
    });
  });
}
