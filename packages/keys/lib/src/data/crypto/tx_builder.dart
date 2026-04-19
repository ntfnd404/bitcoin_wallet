import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:keys/src/data/crypto/bech32.dart';
import 'package:keys/src/data/crypto/hash_utils.dart';
import 'package:keys/src/data/crypto/sighash_input.dart';
import 'package:keys/src/data/crypto/signed_input.dart';

export 'sighash_input.dart';
export 'signed_input.dart';

// ---------------------------------------------------------------------------
// Encoding helpers
// ---------------------------------------------------------------------------

/// Encodes [value] as a 4-byte little-endian integer.
Uint8List leUint32(int value) {
  final b = ByteData(4);
  b.setUint32(0, value, Endian.little);

  return b.buffer.asUint8List();
}

/// Encodes [value] as an 8-byte little-endian integer.
Uint8List leUint64(int value) {
  // Dart's int is 64-bit on most platforms; split into two 32-bit halves
  final b = ByteData(8);
  b.setUint32(0, value & 0xFFFFFFFF, Endian.little);
  b.setUint32(4, (value >> 32) & 0xFFFFFFFF, Endian.little);

  return b.buffer.asUint8List();
}

/// Encodes [value] as a compact Bitcoin varint.
Uint8List varint(int value) {
  if (value < 0xfd) {
    return Uint8List.fromList([value]);
  } else if (value <= 0xffff) {
    final b = ByteData(3);
    b.setUint8(0, 0xfd);
    b.setUint16(1, value, Endian.little);

    return b.buffer.asUint8List();
  } else {
    final b = ByteData(5);
    b.setUint8(0, 0xfe);
    b.setUint32(1, value, Endian.little);

    return b.buffer.asUint8List();
  }
}

/// Reverses the bytes of a hex txid for Bitcoin's little-endian wire format.
///
/// Display txids are shown as big-endian hex; on the wire they are reversed.
Uint8List txidToBytes(String txid) {
  final bytes = hexToBytes(txid);

  return Uint8List.fromList(bytes.reversed.toList());
}

/// Double SHA256: SHA256(SHA256(data)).
Uint8List sha256d(List<int> data) {
  final first = sha256.convert(data);

  return Uint8List.fromList(sha256.convert(first.bytes).bytes);
}

// ---------------------------------------------------------------------------
// Address → scriptPubKey
// ---------------------------------------------------------------------------

/// Converts a bech32/bech32m SegWit address to a P2WPKH scriptPubKey.
///
/// P2WPKH: OP_0 PUSH20 <20-byte-keyhash> — 22 bytes total.
/// Returns null if [address] cannot be decoded with [bech32Hrp].
Uint8List? p2wpkhScriptFromAddress(String address, String bech32Hrp) {
  final program = segwitDecode(address, bech32Hrp);
  if (program == null || program.length != 20) return null;

  // OP_0 (0x00) + OP_PUSHBYTES_20 (0x14) + <20 bytes>
  return Uint8List.fromList([0x00, 0x14, ...program]);
}

// ---------------------------------------------------------------------------
// BIP143 sighash
// ---------------------------------------------------------------------------

/// Computes the BIP143 sighash for a single P2WPKH input.
///
/// Returns SHA256d(preimage) — the 32-byte value that is signed with ECDSA.
/// [inputIndex] is the 0-based position of the input being signed.
Uint8List bip143Sighash({
  required int inputIndex,
  required List<SighashInput> inputs,
  required List<SighashOutput> outputs,
  int version = 2,
  int locktime = 0,
  int hashType = 1, // SIGHASH_ALL
}) {
  // hashPrevouts = SHA256d(outpoint₀ ‖ outpoint₁ ‖ …)
  final prevouts = <int>[];
  for (final inp in inputs) {
    prevouts.addAll(txidToBytes(inp.prevTxid));
    prevouts.addAll(leUint32(inp.prevVout));
  }
  final hashPrevouts = sha256d(prevouts);

  // hashSequence = SHA256d(seq₀ ‖ seq₁ ‖ …)
  final seqs = <int>[];
  for (final inp in inputs) {
    seqs.addAll(leUint32(inp.sequence));
  }
  final hashSequence = sha256d(seqs);

  // hashOutputs = SHA256d(out₀ ‖ out₁ ‖ …)
  final outs = <int>[];
  for (final out in outputs) {
    outs.addAll(leUint64(out.amountSat));
    outs.addAll(varint(out.scriptPubKey.length));
    outs.addAll(out.scriptPubKey);
  }
  final hashOutputs = sha256d(outs);

  final inp = inputs[inputIndex];

  // BIP143 serialisation
  final preimage = <int>[
    ...leUint32(version),
    ...hashPrevouts,
    ...hashSequence,
    ...txidToBytes(inp.prevTxid),
    ...leUint32(inp.prevVout),
    ...varint(inp.scriptCode.length),
    ...inp.scriptCode,
    ...leUint64(inp.amountSat),
    ...leUint32(inp.sequence),
    ...hashOutputs,
    ...leUint32(locktime),
    ...leUint32(hashType),
  ];

  return sha256d(preimage);
}

// ---------------------------------------------------------------------------
// Segwit transaction serialisation
// ---------------------------------------------------------------------------

/// Serialises a signed segwit transaction to its wire-format hex string.
///
/// Format (BIP141):
///   version | marker(0x00) | flag(0x01) | inputs | outputs | witnesses | locktime
String serializeSegwitTx({
  required List<SignedInput> inputs,
  required List<SighashOutput> outputs,
  int version = 2,
  int locktime = 0,
}) {
  final buf = <int>[];

  // Version
  buf.addAll(leUint32(version));

  // SegWit marker + flag
  buf.add(0x00);
  buf.add(0x01);

  // Inputs (scriptSig is empty for P2WPKH)
  buf.addAll(varint(inputs.length));
  for (final inp in inputs) {
    buf.addAll(txidToBytes(inp.prevTxid));
    buf.addAll(leUint32(inp.prevVout));
    buf.add(0x00); // empty scriptSig (varint 0)
    buf.addAll(leUint32(inp.sequence));
  }

  // Outputs
  buf.addAll(varint(outputs.length));
  for (final out in outputs) {
    buf.addAll(leUint64(out.amountSat));
    buf.addAll(varint(out.scriptPubKey.length));
    buf.addAll(out.scriptPubKey);
  }

  // Witness data (one witness stack per input)
  for (final inp in inputs) {
    buf.addAll(varint(inp.witness.length));
    for (final item in inp.witness) {
      buf.addAll(varint(item.length));
      buf.addAll(item);
    }
  }

  // Locktime
  buf.addAll(leUint32(locktime));

  return bytesToHex(Uint8List.fromList(buf));
}
