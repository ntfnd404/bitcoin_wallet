import 'address_type.dart';

final class Address {
  const Address({
    required this.value,
    required this.type,
    required this.walletId,
    required this.index,
    this.derivationPath,
  });

  final String value;
  final AddressType type;
  final String walletId;
  final int index;

  /// Derivation path for HD Wallet addresses (e.g. m/84'/1'/0'/0/0).
  /// Null for Node Wallet addresses — keys are managed by Bitcoin Core.
  final String? derivationPath;

  Address copyWith({
    String? value,
    AddressType? type,
    String? walletId,
    int? index,
    String? derivationPath,
  }) => Address(
    value: value ?? this.value,
    type: type ?? this.type,
    walletId: walletId ?? this.walletId,
    index: index ?? this.index,
    derivationPath: derivationPath ?? this.derivationPath,
  );
}
