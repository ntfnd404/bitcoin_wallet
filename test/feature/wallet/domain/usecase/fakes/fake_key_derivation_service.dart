import 'dart:typed_data';

import 'package:keys/keys.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// Controllable key derivation service for unit tests.
final class FakeKeyDerivationService implements KeyDerivationService {
  final DerivedAddress derivedAddress;

  FakeKeyDerivationService({required this.derivedAddress});

  @override
  DerivedAddress deriveAddress(
    Mnemonic mnemonic,
    AddressType type,
    int index,
  ) =>
      derivedAddress;

  @override
  Uint8List derivePrivateKey(Mnemonic mnemonic, AddressType type, int index) =>
      Uint8List(32);

  @override
  Uint8List derivePublicKey(Mnemonic mnemonic, AddressType type, int index) =>
      Uint8List(33);

  @override
  AccountXpub deriveAccountXpub(Mnemonic mnemonic, AddressType type) =>
      const AccountXpub(xpub: '', derivationPath: '');
}
