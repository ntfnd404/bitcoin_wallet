import 'dart:typed_data';

import 'package:keys/src/data/crypto/base58.dart';
import 'package:keys/src/data/crypto/bech32.dart';
import 'package:keys/src/data/crypto/bip32.dart';
import 'package:keys/src/data/crypto/hash_utils.dart';
import 'package:keys/src/domain/entity/account_xpub.dart';
import 'package:keys/src/domain/entity/derived_address.dart';
import 'package:keys/src/domain/entity/mnemonic.dart';
import 'package:keys/src/domain/service/key_derivation_service.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// BIP32 key derivation and Bitcoin address encoding for all 4 address types.
///
/// Derivation paths use `coin_type` from [network]. Address prefixes depend on network.
final class KeyDerivationServiceImpl implements KeyDerivationService {
  final BitcoinNetwork network;

  const KeyDerivationServiceImpl({required this.network});

  @override
  DerivedAddress deriveAddress(
    Mnemonic mnemonic,
    AddressType type,
    int index,
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

    return DerivedAddress(
      value: addressValue,
      type: type,
      derivationPath: _pathString(type, index),
    );
  }

  @override
  Uint8List derivePrivateKey(Mnemonic mnemonic, AddressType type, int index) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'must be >= 0');
    }

    final seed = mnemonicToSeed(mnemonic.words);
    final master = deriveMasterKey(seed);
    final child = deriveKeyPath(master, _indexPath(type, index));

    return Uint8List.fromList(child.privateKey);
  }

  @override
  Uint8List derivePublicKey(Mnemonic mnemonic, AddressType type, int index) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'must be >= 0');
    }

    final seed = mnemonicToSeed(mnemonic.words);
    final master = deriveMasterKey(seed);
    final child = deriveKeyPath(master, _indexPath(type, index));

    return privateKeyToPublic(child.privateKey);
  }

  @override
  AccountXpub deriveAccountXpub(Mnemonic mnemonic, AddressType type) {
    final seed = mnemonicToSeed(mnemonic.words);
    final master = deriveMasterKey(seed);

    // Account path: m/purpose'/coinType'/0'
    final accountPath = [
      _purpose(type) | 0x80000000,
      network.coinType | 0x80000000,
      0x80000000, // account 0'
    ];

    // Derive the parent (m/purpose'/coinType') to compute the fingerprint
    final parentPath = accountPath.sublist(0, 2);
    final parentKey = deriveKeyPath(master, parentPath);
    final parentPub = privateKeyToPublic(parentKey.privateKey);
    final fingerprint = hash160(parentPub).sublist(0, 4);

    // Derive the account key (m/purpose'/coinType'/0')
    final accountKey = deriveKeyPath(master, accountPath);
    final accountPub = privateKeyToPublic(accountKey.privateKey);

    // BIP32 xpub serialisation
    // Testnet/regtest version: 0x043587CF
    final version = network == BitcoinNetwork.mainnet
        ? Uint8List.fromList([0x04, 0x88, 0xB2, 0x1E]) // mainnet xpub
        : Uint8List.fromList([0x04, 0x35, 0x87, 0xCF]); // testnet/regtest tpub

    final childNumber = Uint8List(4); // account 0' = 0x80000000
    final childNumInt = accountPath.last;
    childNumber[0] = (childNumInt >> 24) & 0xff;
    childNumber[1] = (childNumInt >> 16) & 0xff;
    childNumber[2] = (childNumInt >> 8) & 0xff;
    childNumber[3] = childNumInt & 0xff;

    final payload = Uint8List.fromList([
      ...version,
      3, // depth
      ...fingerprint,
      ...childNumber,
      ...accountKey.chainCode,
      ...accountPub,
    ]);

    return AccountXpub(
      xpub: base58CheckEncode(payload),
      derivationPath: _accountPathString(type),
    );
  }

  String _accountPathString(AddressType type) => "m/${_purpose(type)}'/${network.coinType}'/0'";

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

  String _pathString(AddressType type, int index) => "m/${_purpose(type)}'/${network.coinType}'/0'/0/$index";

  // ---------------------------------------------------------------------------
  // Address encoding
  // ---------------------------------------------------------------------------

  String _encodeAddress(AddressType type, Uint8List compressedPubKey) => switch (type) {
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
