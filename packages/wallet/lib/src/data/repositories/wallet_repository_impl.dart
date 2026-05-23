import 'package:uuid/uuid.dart';
import 'package:wallet/src/data/data_sources/wallet_local_data_source.dart';
import 'package:wallet/src/domain/entities/wallet.dart';
import 'package:wallet/src/domain/exceptions/wallet_exception.dart';
import 'package:wallet/src/domain/gateways/node_wallet_gateway.dart';
import 'package:wallet/src/domain/repositories/hd_wallet_repository.dart';
import 'package:wallet/src/domain/repositories/node_wallet_repository.dart';

/// Unified implementation of [NodeWalletRepository] and [HdWalletRepository].
///
/// Both wallet types share the same local storage. Node wallet creation
/// additionally calls [NodeWalletGateway] to register the wallet in
/// Bitcoin Core before persisting metadata locally.
///
/// Defensive wrapping in [createNodeWallet]: until Phase 3 wraps the
/// `NodeWalletGateway` boundary (Batch 5.7 of BW-0006 Phase 3), RPC
/// errors may surface as [RpcException]. The catch-all maps any non-typed
/// failure to [WalletStorageException] so callers see only wallet's
/// language.
final class WalletRepositoryImpl implements NodeWalletRepository, HdWalletRepository {
  final WalletLocalDataSource _localDataSource;
  final NodeWalletGateway _remoteDataSource;

  const WalletRepositoryImpl({
    required this._localDataSource,
    required this._remoteDataSource,
  });

  @override
  Future<NodeWallet> createNodeWallet(String name) async {
    try {
      await _remoteDataSource.createWallet(name);
      final wallet = NodeWallet(
        id: const Uuid().v4(),
        name: name,
        createdAt: DateTime.now().toUtc(),
      );
      await _localDataSource.saveWallet(wallet);

      return wallet;
    } on WalletException {
      // Already in wallet's language — preserve subtype.
      rethrow;
    } catch (_, stack) {
      // RPC errors (until remote DS is wrapped in Batch 5.7) and any other
      // unexpected non-wallet exception. Programmer errors (TypeError, etc.)
      // also funnel here — acceptable cost for createNodeWallet contract
      // safety until the remote boundary is hardened.
      Error.throwWithStackTrace(const WalletStorageException(), stack);
    }
  }

  @override
  Future<void> saveWallet(HdWallet wallet) => _localDataSource.saveWallet(wallet);

  @override
  Future<List<Wallet>> getWallets() => _localDataSource.getWallets();
}
