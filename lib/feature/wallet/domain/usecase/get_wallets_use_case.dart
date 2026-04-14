import 'package:domain/domain.dart';

/// Returns all wallets across all wallet types.
///
/// The unified [WalletRepository] stores node and HD wallets together;
/// [Wallet.type] distinguishes them at the call site.
final class GetWalletsUseCase {
  final WalletRepository _walletRepository;

  const GetWalletsUseCase({required WalletRepository walletRepository})
      : _walletRepository = walletRepository;

  Future<List<Wallet>> call() => _walletRepository.getWallets();
}
