import 'package:rpc_client/rpc_client.dart';
import 'package:transaction/transaction.dart';

/// Node-wallet transaction operations: address generation, raw transaction
/// construction, and Core-side signing.
///
/// Broadcasting is delegated to [BroadcastGatewayImpl].
///
/// Wraps RPC / network / parse failures in the appropriate
/// [TransactionException] subtype per method.
final class NodeTransactionGatewayImpl implements NodeTransactionGateway {
  final BitcoinRpcClient _rpcClient;

  const NodeTransactionGatewayImpl({required BitcoinRpcClient rpcClient}) : _rpcClient = rpcClient;

  /// Generates a new bech32 (P2WPKH) address in [walletName].
  @override
  Future<String> getNewAddress(String walletName) async {
    try {
      final result = await _rpcClient.call(
        'getnewaddress',
        ['', 'bech32'],
        walletName,
      );

      return result as String;
    } catch (_, stack) {
      Error.throwWithStackTrace(const TransactionPreparationException(), stack);
    }
  }

  /// Builds an unsigned raw transaction via `createrawtransaction`.
  ///
  /// [outputs] maps each recipient address to a BTC amount (8 decimal places).
  @override
  Future<String> createRawTransaction({
    required List<({String txid, int vout})> inputs,
    required Map<String, double> outputs,
  }) async {
    try {
      final rpcInputs = inputs.map((i) => {'txid': i.txid, 'vout': i.vout}).toList();

      final result = await _rpcClient.call(
        'createrawtransaction',
        [rpcInputs, outputs],
      );

      return result as String;
    } catch (_, stack) {
      Error.throwWithStackTrace(const TransactionPreparationException(), stack);
    }
  }

  /// Signs [hexTx] using Bitcoin Core's wallet keys.
  ///
  /// Returns the signed hex string. Throws [TransactionSigningException] if
  /// signing is incomplete or RPC fails.
  @override
  Future<String> signRawTransactionWithWallet(
    String walletName,
    String hexTx,
  ) async {
    try {
      final result = await _rpcClient.call(
        'signrawtransactionwithwallet',
        [hexTx],
        walletName,
      );

      final map = result as Map<String, Object?>;
      final complete = map['complete'] as bool? ?? false;
      if (!complete) {
        throw const TransactionSigningException();
      }

      return map['hex'] as String;
    } on TransactionSigningException {
      // Local incomplete-signing throw — preserve type, do not re-wrap.
      rethrow;
    } catch (_, stack) {
      Error.throwWithStackTrace(const TransactionSigningException(), stack);
    }
  }
}
