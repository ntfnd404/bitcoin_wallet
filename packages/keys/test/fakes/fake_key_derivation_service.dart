import 'dart:typed_data';

import 'package:keys/src/domain/entity/account_xpub.dart';
import 'package:keys/src/domain/entity/derived_address.dart';
import 'package:keys/src/domain/entity/mnemonic.dart';
import 'package:keys/src/domain/service/key_derivation_service.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// Package-local fake for [KeyDerivationService].
///
/// Supports configuring a throwable on [derivePrivateKey] to enable tests for
/// error-mapping paths (T3, T5).
final class FakeKeyDerivationService implements KeyDerivationService {
  /// If set, [derivePrivateKey] throws this value.
  Object? throwOnDerivePrivateKey;

  Uint8List privateKeyResult;
  Uint8List publicKeyResult;

  FakeKeyDerivationService({
    Uint8List? privateKeyResult,
    Uint8List? publicKeyResult,
  })  : privateKeyResult = privateKeyResult ?? Uint8List(32),
        publicKeyResult = publicKeyResult ?? Uint8List(33);

  @override
  Uint8List derivePrivateKey(Mnemonic mnemonic, AddressType type, int index) {
    final throws = throwOnDerivePrivateKey;
    if (throws != null) throw throws;

    return privateKeyResult;
  }

  @override
  Uint8List derivePublicKey(Mnemonic mnemonic, AddressType type, int index) =>
      publicKeyResult;

  @override
  DerivedAddress deriveAddress(Mnemonic mnemonic, AddressType type, int index) =>
      DerivedAddress(
        value: 'bcrt1qfakeaddress',
        type: type,
        derivationPath: "m/84'/1'/0'/0/$index",
      );

  @override
  AccountXpub deriveAccountXpub(Mnemonic mnemonic, AddressType type) =>
      const AccountXpub(
        xpub: 'xpub_fake',
        derivationPath: "m/84'/1'/0'",
      );
}
