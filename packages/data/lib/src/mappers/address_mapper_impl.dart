import 'dart:convert';

import 'package:data/src/mappers/address_mapper.dart';
import 'package:domain/domain.dart';

/// Serialization/deserialization for [Address] entities.
final class AddressMapperImpl extends AddressMapper {
  const AddressMapperImpl();

  @override
  Converter<Address, Map<String, Object?>> get encoder => const _AddressEntityToMapConverter();

  @override
  Converter<Map<String, Object?>, Address> get decoder => const _MapToAddressEntityConverter();
}

/// Converts [Address] → JSON Map (for storage/network)
final class _AddressEntityToMapConverter extends Converter<Address, Map<String, Object?>> {
  const _AddressEntityToMapConverter();

  @override
  Map<String, Object?> convert(Address input) => {
    'value': input.value,
    'type': input.type.name,
    'walletId': input.walletId,
    'index': input.index,
    if (input.derivationPath != null) 'derivationPath': input.derivationPath,
  };
}

/// Converts JSON Map → AddressEntity (из storage/network)
final class _MapToAddressEntityConverter extends Converter<Map<String, Object?>, Address> {
  const _MapToAddressEntityConverter();

  @override
  Address convert(Map<String, Object?> input) => Address(
    value: input['value'] as String,
    type: AddressType.values.byName(input['type'] as String),
    walletId: input['walletId'] as String,
    index: input['index'] as int,
    derivationPath: input['derivationPath'] as String?,
  );
}
