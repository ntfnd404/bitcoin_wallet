import 'package:transaction/src/domain/entity/broadcasted_tx.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/broadcast_gateway.dart';

/// Broadcasts a raw signed transaction and fetches its confirmation status.
final class BroadcastTransactionUseCase {
  final BroadcastGateway _dataSource;

  const BroadcastTransactionUseCase({required BroadcastGateway dataSource}) : _dataSource = dataSource;

  /// Broadcasts [rawHex] and returns the resulting txid.
  Future<String> broadcast(String rawHex) async {
    try {
      return await _dataSource.broadcast(rawHex);
    } on TransactionException {
      rethrow;
    } on Exception catch (_, stack) {
      // 4-criteria (C1: translate to BC language, C2: n/a — no sensitive material, C3: preserve stack, C4: typed recovery for caller).
      // TODO(ntfnd404): narrow to on RpcException once rpc_client dep is wired in pubspec.
      Error.throwWithStackTrace(const TransactionBroadcastException(), stack);
    }
    // Programmer errors (StateError, ArgumentError, TypeError) propagate.
  }

  /// Fetches transaction info for verification via `getrawtransaction`.
  Future<BroadcastedTx> getTransaction(String txid) async {
    try {
      return await _dataSource.getTransaction(txid);
    } on TransactionException {
      rethrow;
    } on Exception catch (_, stack) {
      // 4-criteria (C1: translate to BC language, C2: n/a — no sensitive material, C3: preserve stack, C4: typed recovery for caller).
      // TODO(ntfnd404): narrow to on RpcException once rpc_client dep is wired in pubspec.
      Error.throwWithStackTrace(const TransactionFetchException(), stack);
    }
    // Programmer errors propagate.
  }
}
