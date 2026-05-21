import 'package:wallet/src/domain/entity/wallet.dart';

/// Maps [Wallet] subtypes to and from their JSON-compatible [Map]
/// representation used for persistence.
///
/// Follows the Data Mapper pattern (Fowler, PoEAA).
final class WalletMapper {
  const WalletMapper();

  Map<String, Object?> encode(Wallet wallet) => switch (wallet) {
    NodeWallet() => {
      'type': 'node',
      'id': wallet.id,
      'name': wallet.name,
      'createdAt': wallet.createdAt.toIso8601String(),
    },
    HdWallet() => {
      'type': 'hd',
      'id': wallet.id,
      'name': wallet.name,
      'createdAt': wallet.createdAt.toIso8601String(),
    },
  };

  Wallet decode(Map<String, Object?> map) {
    final id = map['id'] as String;
    final name = map['name'] as String;
    final createdAt = DateTime.parse(map['createdAt'] as String);

    return switch (map['type'] as String) {
      'node' => NodeWallet(id: id, name: name, createdAt: createdAt),
      'hd' => HdWallet(id: id, name: name, createdAt: createdAt),
      final t => throw FormatException('Unknown wallet type: $t'),
    };
  }
}
