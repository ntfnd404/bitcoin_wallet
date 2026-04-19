import 'package:rpc_client/rpc_client.dart';
import 'package:transaction/transaction.dart';

/// Mines blocks to a given address via `generatetoaddress` (regtest only).
final class BlockGenerationDataSourceImpl implements BlockGenerationDataSource {
  final BitcoinRpcClient _rpcClient;

  const BlockGenerationDataSourceImpl({required BitcoinRpcClient rpcClient})
      : _rpcClient = rpcClient;

  @override
  Future<List<String>> generateToAddress(int count, String address) async {
    final result = await _rpcClient.call(
      'generatetoaddress',
      [count, address],
    );

    final list = result as List<Object?>;

    return list.cast<String>();
  }
}
