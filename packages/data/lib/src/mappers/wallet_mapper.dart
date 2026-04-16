import 'dart:convert';

import 'package:domain/domain.dart';

/// Base class for [Wallet] serialization/deserialization.
///
/// Follows the same Codec pattern as [AddressMapper].
abstract base class WalletMapper extends Codec<Wallet, Map<String, Object?>> {
  const WalletMapper();
}
