import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

/// Immutable container for application-level infrastructure dependencies.
///
/// Contains repositories, gateway ports, and services only — no use cases.
/// Use cases are feature-level and are created inside [WalletScopeBlocFactory].
@immutable
final class AppDependencies {
  final WalletRepository walletRepository;
  final AddressRepository addressRepository;
  final BitcoinCoreGateway bitcoinCoreGateway;
  final SeedRepository seedRepository;
  final Bip39Service bip39Service;
  final KeyDerivationService keyDerivationService;

  const AppDependencies({
    required this.walletRepository,
    required this.addressRepository,
    required this.bitcoinCoreGateway,
    required this.seedRepository,
    required this.bip39Service,
    required this.keyDerivationService,
  });
}
