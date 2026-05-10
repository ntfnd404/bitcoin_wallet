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
    } catch (e, stack) {
      Error.throwWithStackTrace(const TransactionBroadcastException(), stack);
    }
  }

  /// Fetches transaction info for verification via `getrawtransaction`.
  Future<BroadcastedTx> getTransaction(String txid) async {
    try {
      return await _dataSource.getTransaction(txid);
    } catch (e, stack) {
      Error.throwWithStackTrace(const TransactionFetchException(), stack);
    }
  }
}
