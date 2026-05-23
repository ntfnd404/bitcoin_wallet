part of 'wallet.dart';

/// Non-custodial HD wallet — keys are derived locally from a BIP39 seed phrase.
final class HdWallet extends Wallet {
  const HdWallet({
    required super.id,
    required super.name,
    required super.createdAt,
  });

  HdWallet copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) => HdWallet(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
}
