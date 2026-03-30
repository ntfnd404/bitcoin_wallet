import '../entity/wallet.dart';
import 'wallet_repository.dart';

/// Node Wallet operations — keys managed by Bitcoin Core via RPC.
abstract interface class NodeWalletRepository implements WalletRepository {
  /// Creates a new wallet on Bitcoin Core via RPC `createwallet`.
  Future<Wallet> createNodeWallet(String name);
}
