import 'package:transaction/src/domain/entity/utxo.dart';

/// Outbound port for fetching unspent outputs from a Bitcoin node.
abstract interface class UtxoGateway {
  /// Fetches unspent outputs via `listunspent` for [walletName].
  Future<List<Utxo>> getUtxos(String walletName);
}
