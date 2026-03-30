import 'package:domain/domain.dart';

/// Immutable container that holds all application-level dependencies.
///
/// Fields correspond to domain interfaces from the `domain` package.
/// Passed down the widget tree via [AppScope].
final class AppDependencies {
  const AppDependencies({
    required this.nodeWalletRepository,
    required this.hdWalletRepository,
    required this.seedRepository,
    required this.bip39Service,
    required this.keyDerivationService,
  });

  final NodeWalletRepository nodeWalletRepository;
  final HdWalletRepository hdWalletRepository;
  final SeedRepository seedRepository;
  final Bip39Service bip39Service;
  final KeyDerivationService keyDerivationService;
}
