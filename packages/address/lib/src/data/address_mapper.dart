import 'package:address/src/domain/entity/address.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// Maps [Address] domain entities to and from their JSON-compatible [Map]
/// representation used for persistence.
///
/// Follows the Data Mapper pattern (Fowler, PoEAA): isolates domain objects
/// from persistence format details.
final class AddressMapper {
  const AddressMapper();

  Map<String, Object?> encode(Address address) => {
    'value': address.value,
    'type': address.type.name,
    'walletId': address.walletId,
    'index': address.index,
    if (address.derivationPath != null) 'derivationPath': address.derivationPath,
  };

  Address decode(Map<String, Object?> map) => Address(
    value: map['value'] as String,
    type: AddressType.values.byName(map['type'] as String),
    walletId: map['walletId'] as String,
    index: map['index'] as int,
    derivationPath: map['derivationPath'] as String?,
  );
}
