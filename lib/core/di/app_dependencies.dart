import 'package:address/address_assembly.dart';
import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:keys/keys_assembly.dart';
import 'package:transaction/transaction_assembly.dart';
import 'package:wallet/wallet_assembly.dart';

/// Immutable container for application-level module assemblies.
///
/// Each module owns its repositories, data sources, and use cases.
@immutable
final class AppDependencies {
  final KeysAssembly keys;
  final WalletAssembly wallet;
  final AddressAssembly address;
  final TransactionAssembly transaction;
  final AppEventBus eventBus;

  const AppDependencies({
    required this.keys,
    required this.wallet,
    required this.address,
    required this.transaction,
    required this.eventBus,
  });
}
