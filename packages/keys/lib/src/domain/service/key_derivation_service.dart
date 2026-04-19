import 'dart:typed_data';

import 'package:keys/src/domain/entity/account_xpub.dart';
import 'package:keys/src/domain/entity/derived_address.dart';
import 'package:keys/src/domain/entity/mnemonic.dart';
import 'package:shared_kernel/shared_kernel.dart';

abstract interface class KeyDerivationService {
  /// Derives a Bitcoin address from [mnemonic] at [type] and [index].
  ///
  /// Derivation paths (coin_type depends on active [BitcoinNetwork]):
  /// - legacy         → m/44'/[coinType]'/0'/0/[index]
  /// - wrappedSegwit  → m/49'/[coinType]'/0'/0/[index]
  /// - nativeSegwit   → m/84'/[coinType]'/0'/0/[index]
  /// - taproot        → m/86'/[coinType]'/0'/0/[index]
  ///
  /// [index] must be >= 0.
  DerivedAddress deriveAddress(
    Mnemonic mnemonic,
    AddressType type,
    int index,
  );

  /// Returns the compressed secp256k1 private key (32 bytes) at the given
  /// derivation path for [type] and [index].
  ///
  /// The caller is responsible for zeroing the returned buffer after use.
  Uint8List derivePrivateKey(
    Mnemonic mnemonic,
    AddressType type,
    int index,
  );

  /// Returns the compressed secp256k1 public key (33 bytes) at the given
  /// derivation path for [type] and [index].
  Uint8List derivePublicKey(
    Mnemonic mnemonic,
    AddressType type,
    int index,
  );

  /// Returns the account-level extended public key at `m/purpose'/coinType'/0'`.
  ///
  /// The xpub is Base58Check-encoded in the standard BIP32 format
  /// (testnet version bytes `0x043587CF` for regtest).
  AccountXpub deriveAccountXpub(Mnemonic mnemonic, AddressType type);
}
