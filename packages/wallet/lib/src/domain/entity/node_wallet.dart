part of 'wallet.dart';

/// Custodial wallet — keys are managed by Bitcoin Core.
final class NodeWallet extends Wallet {
  const NodeWallet({
    required super.id,
    required super.name,
    required super.createdAt,
  });

  NodeWallet copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) => NodeWallet(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
}
