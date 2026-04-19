import 'package:rpc_client/rpc_client.dart';
import 'package:transaction/transaction.dart';

/// Node-wallet transaction operations: address generation, raw transaction
/// construction, and Core-side signing.
///
/// Broadcasting is delegated to [BroadcastDataSourceImpl].
final class NodeTransactionDataSourceImpl implements NodeTransactionDataSource {
  final BitcoinRpcClient _rpcClient;

  const NodeTransactionDataSourceImpl({required BitcoinRpcClient rpcClient})
      : _rpcClient = rpcClient;

  /// Generates a new bech32 (P2WPKH) address in [walletName].
  @override
  Future<String> getNewAddress(String walletName) async {
    final result = await _rpcClient.call(
      'getnewaddress',
      ['', 'bech32'],
      walletName,
    );

    return result as String;
  }

  /// Builds an unsigned raw transaction via `createrawtransaction`.
  ///
  /// [outputs] maps each recipient address to a BTC amount (8 decimal places).
  @override
  Future<String> createRawTransaction({
    required List<({String txid, int vout})> inputs,
    required Map<String, double> outputs,
  }) async {
    final rpcInputs = inputs
        .map((i) => {'txid': i.txid, 'vout': i.vout})
        .toList();

    final result = await _rpcClient.call(
      'createrawtransaction',
      [rpcInputs, outputs],
    );

    return result as String;
  }

  /// Signs [hexTx] using Bitcoin Core's wallet keys.
  ///
  /// Returns the signed hex string. Throws [RpcException] if signing is
  /// incomplete (e.g. missing private key for an input).
  @override
  Future<String> signRawTransactionWithWallet(
    String walletName,
    String hexTx,
  ) async {
    final result = await _rpcClient.call(
      'signrawtransactionwithwallet',
      [hexTx],
      walletName,
    );

    final map = result as Map<String, Object?>;
    final complete = map['complete'] as bool? ?? false;
    if (!complete) {
      throw RpcException(
        'signrawtransactionwithwallet',
        {'code': -1, 'message': 'Signing incomplete: ${map['errors']}'},
      );
    }

    return map['hex'] as String;
  }
}
