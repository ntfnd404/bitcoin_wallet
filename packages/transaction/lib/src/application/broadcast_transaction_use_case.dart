import 'package:transaction/src/domain/data_sources/broadcast_data_source.dart';
import 'package:transaction/src/domain/entity/broadcasted_tx.dart';

/// Broadcasts a raw signed transaction and fetches its confirmation status.
final class BroadcastTransactionUseCase {
  final BroadcastDataSource _dataSource;

  const BroadcastTransactionUseCase({required BroadcastDataSource dataSource})
      : _dataSource = dataSource;

  /// Broadcasts [rawHex] and returns the resulting txid.
  Future<String> broadcast(String rawHex) => _dataSource.broadcast(rawHex);

  /// Fetches transaction info for verification via `getrawtransaction`.
  Future<BroadcastedTx> getTransaction(String txid) =>
      _dataSource.getTransaction(txid);
}
