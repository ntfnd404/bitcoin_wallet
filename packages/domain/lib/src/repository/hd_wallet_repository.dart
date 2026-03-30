import '../entity/mnemonic.dart';
import '../entity/wallet.dart';
import 'wallet_repository.dart';

/// HD Wallet operations — keys derived locally from a BIP39 mnemonic.
abstract interface class HdWalletRepository implements WalletRepository {
  /// Creates a new HD Wallet, generates a BIP39 mnemonic, stores the seed,
  /// and returns both the wallet metadata and the mnemonic.
  ///
  /// [wordCount] must be 12 or 24.
  Future<(Wallet, Mnemonic)> createHDWallet(String name, {int wordCount = 12});

  /// Restores an HD Wallet from an existing [mnemonic] after BIP39 validation.
  ///
  /// Throws [ArgumentError] if [mnemonic] fails BIP39 checksum validation.
  Future<Wallet> restoreHDWallet(String name, Mnemonic mnemonic);
}
