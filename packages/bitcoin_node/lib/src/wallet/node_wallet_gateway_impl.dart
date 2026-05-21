import 'package:rpc_client/rpc_client.dart';
import 'package:wallet/wallet.dart';

/// [NodeWalletGateway] backed by [BitcoinRpcClient].
///
/// Wraps RPC / network / parse failures as [WalletNodeException].
/// Preserves the -4 (already-exists) → loadwallet fallback and -35
/// (already-loaded) → success semantics.
final class NodeWalletGatewayImpl implements NodeWalletGateway {
  final BitcoinRpcClient _rpcClient;

  const NodeWalletGatewayImpl({required this._rpcClient});

  @override
  Future<void> createWallet(String walletName) async {
    try {
      try {
        await _rpcClient.call('createwallet', [walletName]);
      } on RpcException catch (e) {
        if (e.code == -4) {
          await _loadWallet(walletName);
        } else {
          rethrow;
        }
      }
    } catch (_, stack) {
      Error.throwWithStackTrace(const WalletNodeException(), stack);
    }
  }

  Future<void> _loadWallet(String walletName) async {
    try {
      await _rpcClient.call('loadwallet', [walletName]);
    } on RpcException catch (e) {
      if (e.code == -35) return;
      rethrow;
    }
  }
}
