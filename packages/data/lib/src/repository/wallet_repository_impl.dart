import 'package:data/src/local/wallet_local_store.dart';
import 'package:domain/domain.dart';

/// [WalletRepository] backed by [WalletLocalStore].
///
/// Single instance serves all wallet types — node and HD wallets share
/// the same storage; [Wallet.type] distinguishes them at query time.
final class WalletRepositoryImpl implements WalletRepository {
  final WalletLocalStore _localStore;

  const WalletRepositoryImpl({required WalletLocalStore localStore}) : _localStore = localStore;

  @override
  Future<void> saveWallet(Wallet wallet) => _localStore.saveWallet(wallet);

  @override
  Future<List<Wallet>> getWallets() => _localStore.getWallets();
}
