import 'dart:typed_data';

/// BIP32 extended key — private key + chain code pair.
///
/// Both components must be exactly 32 bytes per BIP32 spec.
final class ExtendedKey {
  final Uint8List privateKey;
  final Uint8List chainCode;

  ExtendedKey({
    required this.privateKey,
    required this.chainCode,
  }) {
    if (privateKey.length != 32) {
      throw ArgumentError.value(
        privateKey.length,
        'privateKey',
        'BIP32 requires exactly 32 bytes',
      );
    }
    if (chainCode.length != 32) {
      throw ArgumentError.value(
        chainCode.length,
        'chainCode',
        'BIP32 requires exactly 32 bytes',
      );
    }
  }
}
