import 'dart:convert';

import 'package:domain/domain.dart';

abstract base class AddressMapper extends Codec<Address, Map<String, Object?>> {
  const AddressMapper();
}
