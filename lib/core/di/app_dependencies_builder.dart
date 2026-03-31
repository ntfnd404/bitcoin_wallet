import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:storage/storage.dart';

import '../constants/app_constants.dart';
import 'app_dependencies.dart';

/// Composition root — creates and wires all concrete implementations.
///
/// Called once at startup in [main]. Stub implementations are replaced
/// with real ones as Phases 3–4 are completed.
final class AppDependenciesBuilder {
  /// Builds and returns the fully wired [AppDependencies].
  AppDependencies build() {
    final rpcClient = BitcoinRpcClient(
      url: AppConstants.rpcUrl,
      user: AppConstants.rpcUser,
      password: AppConstants.rpcPassword,
    );
    final storage = SecureStorageImpl();
    final nodeLocalStore = WalletLocalStore(
      storage: storage,
      keyPrefix: 'node_',
    );
    return AppDependencies(
      nodeWalletRepository: NodeWalletRepositoryImpl(
        rpcClient: rpcClient,
        localStore: nodeLocalStore,
      ),
      hdWalletRepository: _StubHdWalletRepository(),
      seedRepository: _StubSeedRepository(),
      bip39Service: const Bip39ServiceImpl(),
      keyDerivationService: const KeyDerivationServiceImpl(),
    );
  }
}

// ---------------------------------------------------------------------------
// Stub implementations — replaced in Phase 4.
// All methods throw [UnimplementedError] to fail loudly if called early.
// ---------------------------------------------------------------------------

final class _StubHdWalletRepository implements HdWalletRepository {
  @override
  Future<(Wallet, Mnemonic)> createHDWallet(
    String name, {
    int wordCount = 12,
  }) => throw UnimplementedError();

  @override
  Future<Wallet> restoreHDWallet(String name, Mnemonic mnemonic) => throw UnimplementedError();

  @override
  Future<List<Wallet>> getWallets() => throw UnimplementedError();

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

