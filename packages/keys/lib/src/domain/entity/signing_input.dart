import 'dart:typed_data';

import 'package:shared_kernel/shared_kernel.dart';

/// A UTXO to be spent, together with the derived private key needed to sign it.
///
/// Used as input to [TransactionSigningService]. The private key must have been
/// derived from the wallet's mnemonic before constructing this object.
/// Zeroing is the caller's intent; in practice the Dart VM GC makes zeroing
/// unreliable — the buffer becomes GC-eligible immediately after
/// `signP2wpkh` returns. See Rule SB-6 in `docs/project/conventions.md`.
final class SigningInput {
  /// Txid of the UTXO being spent (display hex — big-endian).
  final String txid;

  /// Output index of the UTXO.
  final int vout;

  /// Amount of this UTXO in satoshis.
  final Satoshi amountSat;

  /// Compressed secp256k1 private key (32 bytes).
  final Uint8List privateKey;

  /// Compressed secp256k1 public key (33 bytes).
  final Uint8List publicKey;

  const SigningInput({
    required this.txid,
    required this.vout,
    required this.amountSat,
    required this.privateKey,
    required this.publicKey,
  });

  @override
  String toString() =>
      'SigningInput(txid: $txid, vout: $vout, amountSat: $amountSat, '
      '<key-material-redacted>)';
}
