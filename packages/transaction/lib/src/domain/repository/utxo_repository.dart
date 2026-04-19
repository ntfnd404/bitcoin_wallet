import 'package:transaction/src/domain/entity/utxo.dart';

/// Contract for fetching wallet UTXOs.
abstract interface class UtxoRepository {
  /// Returns all unspent transaction outputs for the wallet identified by [walletName].
  Future<List<Utxo>> getUtxos(String walletName);
}
