import 'package:domain/domain.dart';

/// Serialization/deserialization for [Address] entities.
final class AddressMapper {
  const AddressMapper._();

  static Map<String, Object?> toMap(Address address) => {
    'value': address.value,
    'type': address.type.name,
    'walletId': address.walletId,
    'index': address.index,
    if (address.derivationPath != null) 'derivationPath': address.derivationPath,
  };

  static Address fromMap(Map<String, Object?> map) => Address(
    value: map['value'] as String,
    type: AddressType.values.byName(map['type'] as String),
    walletId: map['walletId'] as String,
    index: map['index'] as int,
    derivationPath: map['derivationPath'] as String?,
  );
}
