import 'package:domain/src/entity/wallet.dart';

/// Unified storage contract for all wallet types.
///
/// Pure CRUD — no business logic. Both Node and HD wallets use the same
/// repository; the [Wallet.type] field distinguishes them at query time.
abstract interface class WalletRepository {
  /// Persists [wallet] metadata. Overwrites if the same [Wallet.id] exists.
  Future<void> saveWallet(Wallet wallet);

  /// Returns all stored wallets regardless of type.
  Future<List<Wallet>> getWallets();
}
