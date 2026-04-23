import 'package:wallet/src/domain/entity/wallet.dart';
import 'package:wallet/src/domain/repository/wallet_repository.dart';

/// Write contract for HD wallet operations.
///
/// HD wallets are persisted locally only — no remote data source involved.
abstract interface class HdWalletRepository implements WalletRepository {
  /// Persists [wallet] metadata locally. Overwrites if the same id exists.
  Future<void> saveWallet(HdWallet wallet);
}
