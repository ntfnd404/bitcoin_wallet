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
    } on Exception catch (_, stack) {
      // 4-criteria (C1: translate to BC language, C2: n/a — no sensitive material, C3: preserve stack, C4: typed recovery for caller).
      // TODO(ntfnd404): narrow to on RpcException once rpc_client dep is wired in pubspec.
      Error.throwWithStackTrace(const TransactionBroadcastException(), stack);
    }
    // Programmer errors propagate.
  }
}
