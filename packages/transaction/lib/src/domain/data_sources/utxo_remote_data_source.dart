import 'package:transaction/src/domain/entity/utxo.dart';

/// ISP interface for fetching unspent outputs from a Bitcoin node.
///
/// Owned by the transaction module (consumer) — the adapter in bitcoin_node
/// implements this contract, not the other way around.
abstract interface class UtxoRemoteDataSource {
  /// Fetches unspent outputs via `listunspent`.
  ///
  /// [walletName] is the Bitcoin Core wallet name.
  Future<List<Utxo>> getUtxos(String walletName);
}
