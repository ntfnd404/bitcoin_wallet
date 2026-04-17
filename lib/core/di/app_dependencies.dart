import 'package:address/address_assembly.dart';
import 'package:flutter/foundation.dart';
import 'package:keys/keys_assembly.dart';
import 'package:wallet/wallet_assembly.dart';

/// Immutable container for application-level module assemblies.
///
/// Each module owns its repositories, data sources, and use cases.
@immutable
final class AppDependencies {
  final KeysAssembly keys;
  final WalletAssembly wallet;
  final AddressAssembly address;

  const AppDependencies({
    required this.keys,
    required this.wallet,
    required this.address,
  });
}
