/// Outbound port for Node-wallet transaction operations on Bitcoin Core.
///
/// Covers address generation, raw transaction construction, and Core-side signing.
/// Broadcasting is handled separately by [BroadcastGateway].
abstract interface class NodeTransactionGateway {
  /// Generates a new address in [walletName] via `getnewaddress`.
  Future<String> getNewAddress(String walletName);

  /// Builds an unsigned raw transaction via `createrawtransaction`.
  Future<String> createRawTransaction({
    required List<({String txid, int vout})> inputs,
    required Map<String, double> outputs,
  });

  /// Signs [hexTx] using [walletName]'s keys via `signrawtransactionwithwallet`.
  Future<String> signRawTransactionWithWallet(String walletName, String hexTx);
}
