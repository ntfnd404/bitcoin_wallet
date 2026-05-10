import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/block_generation_gateway.dart';

/// Mines [count] blocks to [address] via Bitcoin Core (regtest only).
///
/// Wraps RPC / network failures as [TransactionBroadcastException].
/// Not used in production flows — regtest development helper.
final class MineBlockUseCase {
  final BlockGenerationGateway _dataSource;

  const MineBlockUseCase({required BlockGenerationGateway dataSource}) : _dataSource = dataSource;

  Future<void> call(String address, {int count = 1}) async {
    try {
      await _dataSource.generateToAddress(count, address);
    } catch (_, stack) {
      Error.throwWithStackTrace(const TransactionBroadcastException(), stack);
    }
  }
}
