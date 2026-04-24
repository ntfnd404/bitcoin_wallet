import 'package:wallet/src/domain/entity/wallet.dart';
import 'package:wallet/src/domain/repository/wallet_repository.dart';

/// Write contract for Node wallet operations.
///
/// Combines the remote Bitcoin Core call and the local metadata persist —
/// callers work with a single abstraction regardless of data sources.
abstract interface class NodeWalletRepository implements WalletRepository {
  /// Creates a named wallet in Bitcoin Core and persists its metadata locally.
  Future<NodeWallet> createNodeWallet(String name);
}
