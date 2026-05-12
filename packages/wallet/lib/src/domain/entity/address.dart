import 'package:shared_kernel/shared_kernel.dart';

final class Address {
  final String value;
  final AddressType type;
  final String walletId;
  final int index;

  /// Derivation path for HD Wallet addresses (e.g. m/84'/1'/0'/0/0).
  /// Null for Node Wallet addresses — keys are managed by Bitcoin Core.
  final String? derivationPath;

  Address({
    required this.value,
    required this.type,
    required this.walletId,
    required this.index,
    this.derivationPath,
  }) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'must be >= 0');
    }
  }

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
