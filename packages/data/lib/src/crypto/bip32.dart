import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

import 'hash_utils.dart';

/// BIP32 extended key — private key + chain code pair.
final class ExtendedKey {
  const ExtendedKey({required this.privateKey, required this.chainCode});

  final Uint8List privateKey;
  final Uint8List chainCode;
}

/// BIP39: converts mnemonic words to a 512-bit seed via PBKDF2-HMAC-SHA512.
///
/// Uses 2048 iterations with salt `"mnemonic"` (no passphrase).
Uint8List mnemonicToSeed(List<String> words) {
  final password = Uint8List.fromList(utf8.encode(words.join(' ')));
  final salt = Uint8List.fromList(utf8.encode('mnemonic'));

  final hmac = HMac(SHA512Digest(), 128);
  final derivator = PBKDF2KeyDerivator(hmac)
    ..init(Pbkdf2Parameters(salt, 2048, 64));

  return derivator.process(password);
}

/// BIP32: derives the master extended key from a seed.
///
/// HMAC-SHA512 with key `"Bitcoin seed"`.
ExtendedKey deriveMasterKey(Uint8List seed) {
  final hmac = Hmac(sha512, utf8.encode('Bitcoin seed'));
  final digest = hmac.convert(seed);
  final bytes = Uint8List.fromList(digest.bytes);

  return ExtendedKey(
    privateKey: bytes.sublist(0, 32),
    chainCode: bytes.sublist(32, 64),
  );
}

/// BIP32: derives a child key along the given index path.
///
/// Indices with bit `0x80000000` set are hardened.
ExtendedKey deriveKeyPath(ExtendedKey master, List<int> path) {
  var current = master;
  for (final index in path) {
    current = _deriveChild(current, index);
  }

  return current;
}

/// Computes the compressed public key (33 bytes) from a private key
/// using the secp256k1 curve.
Uint8List privateKeyToPublic(Uint8List privateKey) {
  final params = ECDomainParameters('secp256k1');
  final d = bytesToBigInt(privateKey);
  final point = params.G * d;
  if (point == null || point.isInfinity) {
    throw StateError('Invalid private key: point at infinity');
  }

  final x = point.x?.toBigInteger();
  final y = point.y?.toBigInteger();
  if (x == null || y == null) {
    throw StateError('Invalid EC point coordinates');
  }

  final prefix = y.isEven ? 0x02 : 0x03;

  return Uint8List.fromList([prefix, ...bigIntToBytes(x, 32)]);
}

// ---------------------------------------------------------------------------
// Private
// ---------------------------------------------------------------------------

ExtendedKey _deriveChild(ExtendedKey parent, int index) {
  final isHardened = index >= 0x80000000;

  final data = Uint8List(37);
  if (isHardened) {
    data[0] = 0x00;
    data.setRange(1, 33, parent.privateKey);
  } else {
    final pubKey = privateKeyToPublic(parent.privateKey);
    data.setRange(0, 33, pubKey);
  }

  // Big-endian 4-byte index
  data[33] = (index >> 24) & 0xff;
  data[34] = (index >> 16) & 0xff;
  data[35] = (index >> 8) & 0xff;
  data[36] = index & 0xff;

  final hmac = Hmac(sha512, parent.chainCode);
  final digest = hmac.convert(data);
  final il = Uint8List.fromList(digest.bytes.sublist(0, 32));
  final ir = Uint8List.fromList(digest.bytes.sublist(32, 64));

  final params = ECDomainParameters('secp256k1');
  final parentInt = bytesToBigInt(parent.privateKey);
  final ilInt = bytesToBigInt(il);
  final childInt = (parentInt + ilInt) % params.n;

  return ExtendedKey(
    privateKey: bigIntToBytes(childInt, 32),
    chainCode: ir,
  );
}
