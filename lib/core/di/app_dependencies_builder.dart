import 'package:address/address_assembly.dart';
import 'package:bitcoin_node/bitcoin_node.dart';
import 'package:bitcoin_wallet/core/constants/app_constants.dart';
import 'package:bitcoin_wallet/core/di/app_dependencies.dart';
import 'package:keys/keys_assembly.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:storage/storage.dart';
import 'package:transaction/transaction_assembly.dart';
import 'package:wallet/wallet_assembly.dart';

/// Composition root — wires all concrete infrastructure implementations.
///
/// Called once at startup via [create()].
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
      const secureStorage = SecureStorageImpl();

      final keys = KeysAssembly(
        storage: secureStorage,
        network: AppConstants.network,
      );

      final walletRemoteDataSource = WalletRemoteDataSourceImpl(rpcClient: rpcClient);
      final addressRemoteDataSource = AddressRemoteDataSourceImpl(rpcClient: rpcClient);

      final wallet = WalletAssembly(
        storage: secureStorage,
        remoteDataSource: walletRemoteDataSource,
        bip39Service: keys.bip39Service,
        seedRepository: keys.seedRepository,
      );

      final address = AddressAssembly(
        storage: secureStorage,
        remoteDataSource: addressRemoteDataSource,
        seedRepository: keys.seedRepository,
        keyDerivationService: keys.keyDerivationService,
      );

      final transactionRemoteDataSource =
          TransactionRemoteDataSourceImpl(rpcClient: rpcClient);
      final transaction = TransactionAssembly(
        remoteDataSource: transactionRemoteDataSource,
      );

      final dependencies = AppDependencies(
        keys: keys,
        wallet: wallet,
        address: address,
        transaction: transaction,
      );

      _builder(dependencies);
    } catch (e, s) {
      _onError(e, s);
    }
  }
}
