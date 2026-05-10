import 'package:wallet/src/domain/entity/wallet.dart';

abstract interface class WalletLocalDataSource {
  Future<List<Wallet>> getWallets();

  Future<void> saveWallet(Wallet wallet);
}
