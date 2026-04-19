/// A single input within a decoded transaction.
final class TransactionInput {
  /// Previous output's txid. Null for coinbase inputs.
  final String? prevTxid;

  /// Previous output's index. Null for coinbase inputs.
  final int? prevVout;

  /// scriptSig in hex. Empty for SegWit inputs (witness used instead).
  final String scriptSigHex;

  /// Witness stack items in hex. Empty for non-SegWit inputs.
  final List<String> witness;

  /// Sequence number.
  final int sequence;

  /// True if this is a coinbase input (block reward transaction).
  bool get isCoinbase => prevTxid == null;

  const TransactionInput({
    required this.prevTxid,
    required this.prevVout,
    required this.scriptSigHex,
    required this.witness,
    required this.sequence,
  });
}
