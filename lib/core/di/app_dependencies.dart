import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

/// Immutable container for application-level infrastructure dependencies.
///
/// Contains repositories, data sources, and services only — no use cases.
/// Use cases are feature-level and are created inside feature scopes.
@immutable
final class AppDependencies {
  final WalletRepository walletRepository;
  final AddressRepository addressRepository;
  final BitcoinCoreRemoteDataSource bitcoinCoreRemoteDataSource;
  final SeedRepository seedRepository;
  final Bip39Service bip39Service;
  final KeyDerivationService keyDerivationService;

  const AppDependencies({
    required this.walletRepository,
    required this.addressRepository,
    required this.bitcoinCoreRemoteDataSource,
    required this.seedRepository,
    required this.bip39Service,
    required this.keyDerivationService,
  });
}
