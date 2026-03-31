import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const _alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

/// Base58Check encoding for Bitcoin addresses (P2PKH, P2SH).
///
/// [payload] = version byte ‖ data.
/// Appends a 4-byte double-SHA256 checksum before encoding.
String base58CheckEncode(Uint8List payload) {
  final hash1 = sha256.convert(payload);
  final hash2 = sha256.convert(hash1.bytes);
  final checksum = Uint8List.fromList(hash2.bytes.sublist(0, 4));

  final data = Uint8List.fromList([...payload, ...checksum]);

  // Count leading zero bytes → leading '1' characters
  var leadingZeros = 0;
  for (final byte in data) {
    if (byte != 0) break;
    leadingZeros++;
  }

  // Convert bytes to BigInt, then repeatedly divide by 58
  var value = BigInt.zero;
  for (final byte in data) {
    value = value * BigInt.from(256) + BigInt.from(byte);
  }

  final chars = <String>[];
  final base = BigInt.from(58);
  while (value > BigInt.zero) {
    final remainder = (value % base).toInt();
    value = value ~/ base;
    chars.add(_alphabet[remainder]);
  }

  for (var i = 0; i < leadingZeros; i++) {
    chars.add('1');
  }

  return chars.reversed.join();
}
