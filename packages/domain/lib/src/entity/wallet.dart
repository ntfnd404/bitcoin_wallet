import 'wallet_type.dart';

final class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String name;
  final WalletType type;
  final DateTime createdAt;

  Wallet copyWith({
    String? id,
    String? name,
    WalletType? type,
    DateTime? createdAt,
  }) => Wallet(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
  );
}
