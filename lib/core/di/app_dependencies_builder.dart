import 'package:domain/domain.dart';

import 'app_dependencies.dart';

/// Composition root — creates and wires all concrete implementations.
///
/// Called once at startup in [main]. Stub implementations are replaced
/// with real ones as Phases 3–4 are completed.
final class AppDependenciesBuilder {
  /// Builds and returns the fully wired [AppDependencies].
  AppDependencies build() => AppDependencies(
    walletRepository: _StubWalletRepository(),
    seedRepository: _StubSeedRepository(),
    bip39Service: _StubBip39Service(),
    keyDerivationService: _StubKeyDerivationService(),
  );
}

// ---------------------------------------------------------------------------
// Stub implementations — replaced in Phases 3–4.
// All methods throw [UnimplementedError] to fail loudly if called early.
// ---------------------------------------------------------------------------

final class _StubWalletRepository implements WalletRepository {
  @override
  Future<List<Wallet>> getWallets() => throw UnimplementedError();

  @override
  Future<Wallet> createNodeWallet(String name) => throw UnimplementedError();

  @override
  Future<(Wallet, Mnemonic)> createHDWallet(String name, {int wordCount = 12}) => throw UnimplementedError();

  @override
  Future<Wallet> restoreHDWallet(String name, Mnemonic mnemonic) => throw UnimplementedError();

  @override
  Future<Address> generateAddress(Wallet wallet, AddressType type) => throw UnimplementedError();

  @override
  Future<List<Address>> getAddresses(Wallet wallet) => throw UnimplementedError();
}

final class _StubSeedRepository implements SeedRepository {
  @override
  Future<void> storeSeed(String walletId, Mnemonic mnemonic) => throw UnimplementedError();

  @override
  Future<Mnemonic?> getSeed(String walletId) => throw UnimplementedError();

  @override
  Future<void> deleteSeed(String walletId) => throw UnimplementedError();
}

final class _StubBip39Service implements Bip39Service {
  @override
  Mnemonic generateMnemonic({int wordCount = 12}) => throw UnimplementedError();

  @override
  bool validateMnemonic(Mnemonic mnemonic) => throw UnimplementedError();
}

final class _StubKeyDerivationService implements KeyDerivationService {
  @override
  Address deriveAddress(Mnemonic mnemonic, AddressType type, int index) => throw UnimplementedError();
}
