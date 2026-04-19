import 'dart:typed_data';

// ---------------------------------------------------------------------------
// BIP143 sighash descriptors
// ---------------------------------------------------------------------------

/// Input descriptor needed for BIP143 sighash computation.
final class SighashInput {
  /// Txid of the UTXO being spent (big-endian hex string as displayed).
  final String prevTxid;

  /// Output index of the UTXO being spent.
  final int prevVout;

  /// Amount of the UTXO in satoshis (required by BIP143 for SegWit inputs).
  final int amountSat;

  /// scriptCode for P2WPKH: `OP_DUP OP_HASH160 PUSH20 <keyhash> OP_EQUALVERIFY OP_CHECKSIG`
  ///
  /// keyhash = HASH160(compressed-pubkey).
  final Uint8List scriptCode;

  /// Sequence number (defaults to 0xFFFFFFFE for RBF-disabled, non-locktime).
  final int sequence;

  const SighashInput({
    required this.prevTxid,
    required this.prevVout,
    required this.amountSat,
    required this.scriptCode,
    this.sequence = 0xfffffffe,
  });
}

/// Output descriptor for BIP143 sighash computation.
final class SighashOutput {
  final int amountSat;
  final Uint8List scriptPubKey;

  const SighashOutput({required this.amountSat, required this.scriptPubKey});
}
