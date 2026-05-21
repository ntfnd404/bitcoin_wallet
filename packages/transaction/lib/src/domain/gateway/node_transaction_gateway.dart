import 'package:transaction/src/domain/value_object/tx_output.dart';

/// Outbound port for Node-wallet transaction operations on Bitcoin Core.
///
/// Covers address generation, raw transaction construction, and Core-side signing.
/// Broadcasting is handled separately by [BroadcastGateway].
abstract interface class NodeTransactionGateway {
  /// Generates a new address in [walletName] via `getnewaddress`.
  Future<String> getNewAddress(String walletName);

  /// Builds an unsigned raw transaction via `createrawtransaction`.
  ///
  /// Each [TxOutput] is serialised to the Bitcoin Core RPC format:
  /// - [AddressOutput] → `{"address": amountBtc}`
  /// - [OpReturnOutput] → `{"data": dataHex}` (Core prepends OP_RETURN script)
  Future<String> createRawTransaction({
    required List<({String txid, int vout})> inputs,
    required List<TxOutput> outputs,
  });

  /// Signs [hexTx] using [walletName]'s keys via `signrawtransactionwithwallet`.
  Future<String> signRawTransactionWithWallet(String walletName, String hexTx);
}
