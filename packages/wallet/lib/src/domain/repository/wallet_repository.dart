import 'package:wallet/src/domain/entity/wallet.dart';

/// Read-only contract for listing all stored wallets.
///
/// Both [NodeWalletRepository] and [HdWalletRepository] extend this interface.
abstract interface class WalletRepository {
  Future<List<Wallet>> getWallets();
}
