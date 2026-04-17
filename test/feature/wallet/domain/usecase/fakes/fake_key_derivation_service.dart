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
}
