import 'package:rpc_client/rpc_client.dart';
import 'package:transaction/transaction.dart';

/// Mines blocks to a given address via `generatetoaddress` (regtest only).
final class BlockGenerationGatewayImpl implements BlockGenerationGateway {
  final BitcoinRpcClient _rpcClient;

  const BlockGenerationGatewayImpl({required this._rpcClient});

  @override
  Future<List<String>> generateToAddress(int count, String address) async {
    try {
      final result = await _rpcClient.call(
        'generatetoaddress',
        [count, address],
      );

      final list = result as List<Object?>;

      return list.cast<String>();
    } catch (_, stack) {
      Error.throwWithStackTrace(const TransactionBroadcastException(), stack);
    }
  }
}
