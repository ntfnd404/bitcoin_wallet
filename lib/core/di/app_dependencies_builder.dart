import 'package:bitcoin_wallet/core/constants/app_constants.dart';
import 'package:bitcoin_wallet/core/di/app_dependencies.dart';
import 'package:data/data.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:storage/storage.dart';

/// Composition root — wires all concrete infrastructure implementations.
///
/// Called once at startup via [create()]. Use cases are NOT created here;
/// they live in feature scope (WalletScope, AddressScope).
final class AppDependenciesBuilder {
  final void Function(AppDependencies dependencies) _builder;
  final void Function(Object error, StackTrace stack) _onError;

  AppDependenciesBuilder._({
    required void Function(AppDependencies dependencies) builder,
    required void Function(Object error, StackTrace stack) onError,
  }) : _builder = builder,
       _onError = onError;

  /// Initializes the composition root and builds the app.
  ///
  /// Call this once at startup, typically in main().
  static void create({
    required void Function(AppDependencies dependencies) builder,
    required void Function(Object error, StackTrace stack) onError,
  }) {
    final instance = AppDependenciesBuilder._(builder: builder, onError: onError);
    instance._build();
  }

  void _build() {
    try {
      final rpcClient = BitcoinRpcClient(
        url: AppConstants.rpcUrl,
        user: AppConstants.rpcUser,
        password: AppConstants.rpcPassword,
      );
      final storage = SecureStorageImpl();

      const walletMapper = WalletMapperImpl();
      final walletLocalDataSource = WalletLocalDataSourceImpl(
        storage: storage,
        mapper: walletMapper,
        keyPrefix: 'wallet_',
      );

      const addressMapper = AddressMapperImpl();
      final addressLocalDataSource = AddressLocalDataSourceImpl(
        storage: storage,
        mapper: addressMapper,
      );

      final bitcoinCoreRemoteDataSource = BitcoinCoreRemoteDatasourceImpl(
        rpcClient: rpcClient,
      );

      final dependencies = AppDependencies(
        walletRepository: WalletRepositoryImpl(localDataSource: walletLocalDataSource),
        addressRepository: AddressRepositoryImpl(localStore: addressLocalDataSource),
        bitcoinCoreRemoteDataSource: bitcoinCoreRemoteDataSource,
        seedRepository: SeedRepositoryImpl(storage: storage),
        bip39Service: const Bip39ServiceImpl(),
        keyDerivationService: const KeyDerivationServiceImpl(network: AppConstants.network),
      );

      _builder(dependencies);
    } catch (e, s) {
      _onError(e, s);
    }
  }
}
