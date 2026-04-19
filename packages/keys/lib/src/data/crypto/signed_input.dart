import 'dart:typed_data';

/// A signed P2WPKH input ready for serialisation.
final class SignedInput {
  final String prevTxid;
  final int prevVout;
  final int sequence;

  /// Witness stack: [<DER-sig+hashtype>, <compressed-pubkey>]
  final List<Uint8List> witness;

  const SignedInput({
    required this.prevTxid,
    required this.prevVout,
    required this.sequence,
    required this.witness,
  });
}
