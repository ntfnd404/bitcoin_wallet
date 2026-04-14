import 'wallet_type.dart';

final class Wallet {
  final String id;
  final String name;
  final WalletType type;
  final DateTime createdAt;

  bool get isHd => type == WalletType.hd;

  bool get isNode => type == WalletType.node;

  String get displayLabel => switch (type) {
    WalletType.node => 'Node',
    WalletType.hd => 'HD',
  };

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
  });

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
