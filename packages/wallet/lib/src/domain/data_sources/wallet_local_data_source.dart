import 'package:wallet/src/domain/entity/wallet.dart';

/// Contract for local wallet metadata persistence.
///
/// Implementation lives in the data layer.
abstract interface class WalletLocalDataSource {
  /// Returns all stored wallets.
  Future<List<Wallet>> getWallets();

  /// Persists [wallet] metadata. Overwrites if the same [Wallet.id] exists.
  Future<void> saveWallet(Wallet wallet);
}
