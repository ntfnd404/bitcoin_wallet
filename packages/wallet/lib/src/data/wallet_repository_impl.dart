import 'package:wallet/src/domain/data_sources/wallet_local_data_source.dart';
import 'package:wallet/src/domain/entity/wallet.dart';
import 'package:wallet/src/domain/repository/wallet_repository.dart';

/// [WalletRepository] backed by [WalletLocalDataSource].
///
/// Single instance serves all wallet types — node and HD wallets share
/// the same storage; [Wallet.type] distinguishes them at query time.
final class WalletRepositoryImpl implements WalletRepository {
  final WalletLocalDataSource _localDataSource;

  const WalletRepositoryImpl({required WalletLocalDataSource localDataSource}) : _localDataSource = localDataSource;

  @override
  Future<void> saveWallet(Wallet wallet) => _localDataSource.saveWallet(wallet);

  @override
  Future<List<Wallet>> getWallets() => _localDataSource.getWallets();
}
