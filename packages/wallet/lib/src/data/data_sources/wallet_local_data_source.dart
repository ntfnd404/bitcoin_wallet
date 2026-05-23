import 'package:wallet/src/domain/entities/wallet.dart';

abstract interface class WalletLocalDataSource {
  Future<List<Wallet>> getWallets();

  Future<void> saveWallet(Wallet wallet);
}
