import 'dart:convert';

import 'package:domain/domain.dart';

/// Serialization/deserialization for [Wallet] entities.
final class WalletMapper {
  const WalletMapper._();

  static String toJson(Wallet wallet) => jsonEncode({
    'id': wallet.id,
    'name': wallet.name,
    'type': wallet.type.name,
    'createdAt': wallet.createdAt.toIso8601String(),
  });

  static Wallet fromJson(String json) {
    final map = jsonDecode(json) as Map<String, Object?>;

    return Wallet(
      id: map['id'] as String,
      name: map['name'] as String,
      type: WalletType.values.byName(map['type'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
