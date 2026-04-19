import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:keys/src/data/crypto/hash_utils.dart';
import 'package:pointycastle/export.dart';

/// Signs [sighash] (32-byte message hash) with [privateKey] using ECDSA/secp256k1.
///
/// Signing is deterministic: same (privateKey, sighash) always yields the same
/// signature. k is seeded from sha256(privateKey ‖ sighash) via a Fortuna PRNG,
/// which approximates RFC 6979 determinism without the full HMAC-DRBG chain.
///
/// Returns a DER-encoded signature with the SIGHASH_ALL byte (0x01) appended,
/// ready to be used as a witness stack item in a P2WPKH input.
Uint8List ecdsaSign(Uint8List privateKey, Uint8List sighash) {
  assert(privateKey.length == 32, 'privateKey must be 32 bytes');
  assert(sighash.length == 32, 'sighash must be 32 bytes');

  final params = ECDomainParameters('secp256k1');
  final privInt = bytesToBigInt(privateKey);
  final n = params.n;

  // Deterministic k: seed Fortuna from sha256(privKey ‖ sighash)
  final seed = sha256.convert([...privateKey, ...sighash]).bytes;
  final secureRandom = SecureRandom('Fortuna')
    ..seed(KeyParameter(Uint8List.fromList(seed)));

  // null digest → pass sighash directly as the message hash (no re-hashing)
  final signer = ECDSASigner();
  signer.init(
    true,
    ParametersWithRandom(
      PrivateKeyParameter<ECPrivateKey>(ECPrivateKey(privInt, params)),
      secureRandom,
    ),
  );

  final sig = signer.generateSignature(sighash) as ECSignature;

  // BIP62 low-S normalization — required for standard P2WPKH inputs
  final s = sig.s > n >> 1 ? n - sig.s : sig.s;

  return Uint8List.fromList([...derEncode(ECSignature(sig.r, s)), 0x01]);
}

/// DER-encodes an EC signature.
///
/// Format: 0x30 [total-len] 0x02 [r-len] [r] 0x02 [s-len] [s]
Uint8List derEncode(ECSignature sig) {
  final r = _derInt(sig.r);
  final s = _derInt(sig.s);
  final body = [0x02, r.length, ...r, 0x02, s.length, ...s];

  return Uint8List.fromList([0x30, body.length, ...body]);
}

/// Encodes [value] as a DER unsigned integer.
///
/// Strips leading zero bytes, then prepends 0x00 if the high bit is set
/// (DER integers are signed; the prefix avoids negative interpretation).
Uint8List _derInt(BigInt value) {
  final bytes = bigIntToBytes(value, 32);

  var start = 0;
  while (start < bytes.length - 1 && bytes[start] == 0) {
    start++;
  }

  final trimmed = bytes.sublist(start);

  return (trimmed[0] & 0x80 != 0)
      ? Uint8List.fromList([0x00, ...trimmed])
      : trimmed;
}
