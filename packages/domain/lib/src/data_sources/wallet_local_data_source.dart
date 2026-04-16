import 'package:domain/domain.dart';

/// Contract for local wallet metadata persistence.
///
/// Implementation lives in the data package.
abstract interface class WalletLocalDataSource {
  /// Returns all stored wallets.
  Future<List<Wallet>> getWallets();

  /// Persists [wallet] metadata. Overwrites if the same [Wallet.id] exists.
  Future<void> saveWallet(Wallet wallet);
}
