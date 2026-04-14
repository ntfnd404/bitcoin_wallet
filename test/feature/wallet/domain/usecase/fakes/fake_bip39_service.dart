import 'package:domain/domain.dart';

/// Controllable BIP39 service for unit tests.
final class FakeBip39Service implements Bip39Service {
  final Mnemonic mnemonic;

  /// Controls what [validateMnemonic] returns.
  bool isValid;

  FakeBip39Service({required this.mnemonic, this.isValid = true});

  @override
  Mnemonic generateMnemonic({int wordCount = 12}) => mnemonic;

  @override
  bool validateMnemonic(Mnemonic mnemonic) => isValid;

  @override
  bool isValidWord(String word) => true; // Always valid in tests
}
