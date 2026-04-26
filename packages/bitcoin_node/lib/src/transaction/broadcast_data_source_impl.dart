import 'package:rpc_client/rpc_client.dart';
import 'package:transaction/transaction.dart';

/// Broadcasts raw transactions to the Bitcoin network and verifies them.
///
/// Uses `sendrawtransaction` and `getrawtransaction` — no wallet required.
final class BroadcastDataSourceImpl implements BroadcastDataSource {
  final BitcoinRpcClient _rpcClient;

  const BroadcastDataSourceImpl({required BitcoinRpcClient rpcClient}) : _rpcClient = rpcClient;

  @override
  Future<String> broadcast(String rawHex) async {
    final result = await _rpcClient.call('sendrawtransaction', [rawHex]);

    return result as String;
  }

  @override
  Future<BroadcastedTx> getTransaction(String txid) async {
    // verbose=1 returns decoded JSON
    final result = await _rpcClient.call('getrawtransaction', [txid, 1]);
    final map = result as Map<String, Object?>;

    return BroadcastedTx(
      txid: txid,
      confirmations: (map['confirmations'] as num?)?.toInt() ?? 0,
      hex: map['hex'] as String? ?? '',
    );
  }
}
