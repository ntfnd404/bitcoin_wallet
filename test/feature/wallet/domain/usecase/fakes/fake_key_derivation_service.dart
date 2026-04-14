import 'package:domain/domain.dart';

/// Controllable key derivation service for unit tests.
final class FakeKeyDerivationService implements KeyDerivationService {
  final Address address;

  FakeKeyDerivationService({required this.address});

  @override
  Address deriveAddress(
    Mnemonic mnemonic,
    AddressType type,
    int index,
    String walletId,
  ) =>
      address.copyWith(walletId: walletId);
}
