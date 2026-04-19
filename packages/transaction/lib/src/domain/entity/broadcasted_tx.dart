/// Result of a `getrawtransaction` call — used to verify broadcast.
final class BroadcastedTx {
  final String txid;
  final int confirmations;
  final String hex;

  const BroadcastedTx({
    required this.txid,
    required this.confirmations,
    required this.hex,
  });
}
