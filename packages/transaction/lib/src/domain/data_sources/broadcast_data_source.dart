import 'package:transaction/src/domain/entity/broadcasted_tx.dart';

/// ISP interface for broadcasting and verifying raw transactions.
abstract interface class BroadcastDataSource {
  /// Broadcasts [rawHex] via `sendrawtransaction`.
  ///
  /// Returns the txid on success, throws [RpcException] on failure.
  Future<String> broadcast(String rawHex);

  /// Fetches transaction info via `getrawtransaction <txid> 1`.
  Future<BroadcastedTx> getTransaction(String txid);
}
