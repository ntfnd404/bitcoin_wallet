import 'package:rpc_client/rpc_client.dart';
import 'package:wallet/wallet.dart';

/// [WalletRemoteDataSource] backed by [BitcoinRpcClient].
///
/// Wraps RPC / network / parse failures as [WalletStorageException].
/// Preserves the -4 (already-exists) → loadwallet fallback and -35
/// (already-loaded) → success semantics; only true failures surface as
/// the typed exception.
final class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final BitcoinRpcClient _rpcClient;

  const WalletRemoteDataSourceImpl({required BitcoinRpcClient rpcClient}) : _rpcClient = rpcClient;

  /// Creates a wallet in Bitcoin Core.
  ///
  /// If the wallet already exists on disk (code -4), falls back to
  /// `loadwallet`. If it is already loaded (code -35), treats it as success.
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
      // RPC error not handled by the inner fallback (codes != -4, network
      // failure, parse error, etc.) — surface as wallet-bounded-context.
      Error.throwWithStackTrace(const WalletStorageException(), stack);
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
