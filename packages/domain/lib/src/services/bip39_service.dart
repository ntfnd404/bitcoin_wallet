import 'package:domain/src/entities/mnemonic.dart';

abstract interface class Bip39Service {
  /// Generates a BIP39 mnemonic with [wordCount] words (12 or 24).
  ///
  /// Uses a cryptographically secure random source.
  /// Throws [ArgumentError] if [wordCount] is not 12 or 24.
  Mnemonic generateMnemonic({int wordCount = 12});

  /// Returns `true` if [mnemonic] passes BIP39 checksum validation.
  bool validateMnemonic(Mnemonic mnemonic);

  /// Returns `true` if [word] is a valid BIP39 English word.
  bool isValidWord(String word);
}
