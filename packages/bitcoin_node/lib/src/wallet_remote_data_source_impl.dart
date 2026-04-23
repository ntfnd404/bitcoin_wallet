import 'package:rpc_client/rpc_client.dart';
import 'package:wallet/wallet.dart';

/// [WalletRemoteDataSource] backed by [BitcoinRpcClient].
final class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final BitcoinRpcClient _rpcClient;

  const WalletRemoteDataSourceImpl({required BitcoinRpcClient rpcClient}) : _rpcClient = rpcClient;

  /// Creates a wallet in Bitcoin Core.
  ///
  /// If the wallet already exists on disk (code -4), falls back to
  /// [loadwallet]. If it is already loaded (code -35), treats it as success.
  @override
  Future<void> createWallet(String walletName) async {
    try {
      await _rpcClient.call('createwallet', [walletName]);
    } on RpcException catch (e) {
      if (e.code == -4) {
        await _loadWallet(walletName);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _loadWallet(String walletName) async {
    try {
      await _rpcClient.call('loadwallet', [walletName]);
    } on RpcException catch (e) {
      if (e.code == -35) return; // Already loaded — treat as success.
      rethrow;
    }
  }
}
