import 'package:transaction/src/domain/entity/broadcasted_tx.dart';

/// Outbound port for broadcasting and verifying raw transactions on Bitcoin Core.
abstract interface class BroadcastGateway {
  /// Broadcasts [rawHex] via `sendrawtransaction`.
  Future<String> broadcast(String rawHex);

  /// Fetches transaction info via `getrawtransaction <txid> 1`.
  Future<BroadcastedTx> getTransaction(String txid);
}
