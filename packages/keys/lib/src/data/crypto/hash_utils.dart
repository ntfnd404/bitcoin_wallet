import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/digests/ripemd160.dart';

/// RIPEMD160(SHA256(data)) — standard Bitcoin hash for address generation.
Uint8List hash160(Uint8List data) {
  final sha256Hash = sha256.convert(data);
  final ripemd = RIPEMD160Digest();

  return ripemd.process(Uint8List.fromList(sha256Hash.bytes));
}

/// BIP340 tagged hash: SHA256(SHA256(tag) ‖ SHA256(tag) ‖ data).
Uint8List taggedHash(String tag, Uint8List data) {
  final tagHash = Uint8List.fromList(sha256.convert(utf8.encode(tag)).bytes);
  final combined = Uint8List.fromList([...tagHash, ...tagHash, ...data]);

  return Uint8List.fromList(sha256.convert(combined).bytes);
}

/// Converts big-endian [bytes] to [BigInt].
BigInt bytesToBigInt(Uint8List bytes) {
  var result = BigInt.zero;
  for (final byte in bytes) {
    result = (result << 8) | BigInt.from(byte);
  }

  return result;
}

/// Converts [value] to fixed-length big-endian bytes.
Uint8List bigIntToBytes(BigInt value, int length) {
  final bytes = Uint8List(length);
  var v = value;
  for (var i = length - 1; i >= 0; i--) {
    bytes[i] = (v & BigInt.from(0xff)).toInt();
    v >>= 8;
  }

  return bytes;
}

/// Converts a byte list to a lowercase hex string.
String bytesToHex(Uint8List bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// Converts a hex string to a byte list.
Uint8List hexToBytes(String hex) {
  final bytes = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }

  return bytes;
}
