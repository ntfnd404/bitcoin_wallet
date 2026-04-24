import 'package:uuid/uuid.dart';
import 'package:wallet/src/domain/data_sources/wallet_local_data_source.dart';
import 'package:wallet/src/domain/data_sources/wallet_remote_data_source.dart';
import 'package:wallet/src/domain/entity/wallet.dart';
import 'package:wallet/src/domain/repository/hd_wallet_repository.dart';
import 'package:wallet/src/domain/repository/node_wallet_repository.dart';

/// Unified implementation of [NodeWalletRepository] and [HdWalletRepository].
///
/// Both wallet types share the same local storage. Node wallet creation
/// additionally calls [WalletRemoteDataSource] to register the wallet in
/// Bitcoin Core before persisting metadata locally.
final class WalletRepositoryImpl
    implements NodeWalletRepository, HdWalletRepository {
  final WalletLocalDataSource _localDataSource;
  final WalletRemoteDataSource _remoteDataSource;

  const WalletRepositoryImpl({
    required WalletLocalDataSource localDataSource,
    required WalletRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  @override
  Future<NodeWallet> createNodeWallet(String name) async {
    await _remoteDataSource.createWallet(name);
    final wallet = NodeWallet(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now().toUtc(),
    );
    await _localDataSource.saveWallet(wallet);

    return wallet;
  }

  @override
  Future<void> saveWallet(HdWallet wallet) => _localDataSource.saveWallet(wallet);

  @override
  Future<List<Wallet>> getWallets() => _localDataSource.getWallets();
}
