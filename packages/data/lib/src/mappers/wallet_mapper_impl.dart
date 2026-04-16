import 'dart:convert';

import 'package:data/src/mappers/wallet_mapper.dart';
import 'package:domain/domain.dart';

/// Serialization/deserialization for [Wallet] entities.
final class WalletMapperImpl extends WalletMapper {
  const WalletMapperImpl();

  @override
  Converter<Wallet, Map<String, Object?>> get encoder => const _WalletEntityToMapConverter();

  @override
  Converter<Map<String, Object?>, Wallet> get decoder => const _MapToWalletEntityConverter();
}

/// Converts [Wallet] → JSON Map (for storage)
final class _WalletEntityToMapConverter extends Converter<Wallet, Map<String, Object?>> {
  const _WalletEntityToMapConverter();

  @override
  Map<String, Object?> convert(Wallet input) => {
    'id': input.id,
    'name': input.name,
    'type': input.type.name,
    'createdAt': input.createdAt.toIso8601String(),
  };
}

/// Converts JSON Map → [Wallet] (from storage)
final class _MapToWalletEntityConverter extends Converter<Map<String, Object?>, Wallet> {
  const _MapToWalletEntityConverter();

  @override
  Wallet convert(Map<String, Object?> input) => Wallet(
    id: input['id'] as String,
    name: input['name'] as String,
    type: WalletType.values.byName(input['type'] as String),
    createdAt: DateTime.parse(input['createdAt'] as String),
  );
}
