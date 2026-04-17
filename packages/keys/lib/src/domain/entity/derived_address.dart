import 'package:shared_kernel/shared_kernel.dart';

/// Lightweight result of BIP32 key derivation.
///
/// Contains only the derived address string and its derivation path.
/// The consumer (address module) constructs the full Address entity
/// from this value object.
final class DerivedAddress {
  final String value;
  final AddressType type;
  final String derivationPath;

  const DerivedAddress({
    required this.value,
    required this.type,
    required this.derivationPath,
  });
}
