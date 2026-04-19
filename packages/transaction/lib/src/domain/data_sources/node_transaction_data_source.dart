/// ISP interface for Node-wallet transaction operations (Bitcoin Core).
///
/// Covers address generation, raw transaction construction, and Core-side signing.
/// Broadcasting is handled separately by [BroadcastDataSource].
abstract interface class NodeTransactionDataSource {
  /// Generates a new address in [walletName] via `getnewaddress`.
  Future<String> getNewAddress(String walletName);

  /// Builds an unsigned raw transaction via `createrawtransaction`.
  ///
  /// [inputs] — UTXOs to spend as `(txid, vout)` pairs.
  /// [outputs] — map of `address → BTC amount` (must include change output if any).
  Future<String> createRawTransaction({
    required List<({String txid, int vout})> inputs,
    required Map<String, double> outputs,
  });

  /// Signs [hexTx] using [walletName]'s keys via `signrawtransactionwithwallet`.
  ///
  /// Returns the signed hex string.
  Future<String> signRawTransactionWithWallet(String walletName, String hexTx);
}
