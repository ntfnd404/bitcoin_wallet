import 'dart:typed_data';

import 'package:data/src/crypto/base58.dart';
import 'package:data/src/crypto/bech32.dart';
import 'package:data/src/crypto/bip32.dart';
import 'package:data/src/crypto/hash_utils.dart';
import 'package:domain/domain.dart';
import 'package:pointycastle/export.dart';

/// BIP32 key derivation and Bitcoin address encoding for all 4 address types.
///
/// Derivation paths use `coin_type` from [network]. Address prefixes depend on network.
final class KeyDerivationServiceImpl implements KeyDerivationService {
  final BitcoinNetwork network;

  const KeyDerivationServiceImpl({required this.network});

  @override
  Address deriveAddress(
    Mnemonic mnemonic,
    AddressType type,
    int index,
    String walletId,
  ) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'must be >= 0');
    }

    final seed = mnemonicToSeed(mnemonic.words);
    final master = deriveMasterKey(seed);
    final path = _indexPath(type, index);
    final child = deriveKeyPath(master, path);
    final publicKey = privateKeyToPublic(child.privateKey);
    final addressValue = _encodeAddress(type, publicKey);

    return Address(
      value: addressValue,
      type: type,
      walletId: walletId,
      index: index,
      derivationPath: _pathString(type, index),
    );
  }

  // ---------------------------------------------------------------------------
  // Derivation paths
  // ---------------------------------------------------------------------------

  List<int> _indexPath(AddressType type, int index) {
    final purpose = _purpose(type);

    return [
      purpose | 0x80000000,
      network.coinType | 0x80000000,
      0x80000000, // account 0'
      0, // external chain
      index,
    ];
  }

  int _purpose(AddressType type) => switch (type) {
    AddressType.legacy => 44,
    AddressType.wrappedSegwit => 49,
    AddressType.nativeSegwit => 84,
    AddressType.taproot => 86,
  };

  String _pathString(AddressType type, int index) =>
      "m/${_purpose(type)}'/${network.coinType}'/0'/0/$index";

  // ---------------------------------------------------------------------------
  // Address encoding
  // ---------------------------------------------------------------------------

  String _encodeAddress(AddressType type, Uint8List compressedPubKey) =>
      switch (type) {
        AddressType.legacy => _encodeP2pkh(compressedPubKey),
        AddressType.wrappedSegwit => _encodeP2shP2wpkh(compressedPubKey),
        AddressType.nativeSegwit => _encodeP2wpkh(compressedPubKey),
        AddressType.taproot => _encodeP2tr(compressedPubKey),
      };

  /// P2PKH: Base58Check(0x6F ‖ HASH160(pubkey))
  String _encodeP2pkh(Uint8List pubKey) {
    final h = hash160(pubKey);

    return base58CheckEncode(Uint8List.fromList([0x6f, ...h]));
  }

  /// P2SH-P2WPKH: Base58Check(0xC4 ‖ HASH160(witnessProgram))
  ///
  /// witnessProgram = OP_0 (0x00) ‖ PUSH_20 (0x14) ‖ HASH160(pubkey)
  String _encodeP2shP2wpkh(Uint8List pubKey) {
    final keyHash = hash160(pubKey);
    final witnessProgram = Uint8List.fromList([0x00, 0x14, ...keyHash]);
    final scriptHash = hash160(witnessProgram);

    return base58CheckEncode(Uint8List.fromList([0xc4, ...scriptHash]));
  }

  /// P2WPKH: Bech32(HRP, 0, HASH160(pubkey)) — where HRP is from [network]
  String _encodeP2wpkh(Uint8List pubKey) {
    final h = hash160(pubKey);

    return segwitEncode(network.bech32Hrp, 0, h);
  }

  /// P2TR: Bech32m(HRP, 1, tweaked_x_only_pubkey) — where HRP is from [network]
  ///
  /// Key-path-only spend (no script tree).
  String _encodeP2tr(Uint8List compressedPubKey) {
    final params = ECDomainParameters('secp256k1');

    // x-only public key (32 bytes — drop the prefix byte)
    final xOnly = compressedPubKey.sublist(1);

    // lift_x: reconstruct EC point with even Y (prefix 0x02)
    final liftedBytes = Uint8List.fromList([0x02, ...xOnly]);
    final internalPoint = params.curve.decodePoint(liftedBytes);
    if (internalPoint == null || internalPoint.isInfinity) {
      throw StateError('Invalid internal public key');
    }

    // BIP341 tweak: t = tagged_hash("TapTweak", x_only_pubkey)
    final tweakBytes = taggedHash('TapTweak', xOnly);
    final tweakInt = bytesToBigInt(tweakBytes);
    if (tweakInt >= params.n) {
      throw StateError('Taproot tweak exceeds curve order');
    }

    // Output key Q = P + t·G
    final tweakPoint = params.G * tweakInt;
    if (tweakPoint == null) {
      throw StateError('Invalid tweak point');
    }
    final outputPoint = internalPoint + tweakPoint;
    if (outputPoint == null || outputPoint.isInfinity) {
      throw StateError('Invalid taproot output point');
    }

    final qx = outputPoint.x?.toBigInteger();
    if (qx == null) {
      throw StateError('Invalid taproot output x coordinate');
    }

    return segwitEncode(network.bech32Hrp, 1, bigIntToBytes(qx, 32));
  }
}
