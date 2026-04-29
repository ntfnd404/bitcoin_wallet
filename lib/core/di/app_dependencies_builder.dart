import 'package:address/address_assembly.dart';
import 'package:bitcoin_node/bitcoin_node.dart';
import 'package:bitcoin_wallet/core/adapters/hd_address_data_source_impl.dart';
import 'package:bitcoin_wallet/core/adapters/hd_transaction_signer.dart';
import 'package:bitcoin_wallet/core/config/config.dart';
import 'package:bitcoin_wallet/core/di/app_dependencies.dart';
import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:keys/keys_assembly.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:storage/storage.dart';
import 'package:transaction/transaction.dart';
import 'package:transaction/transaction_assembly.dart';
import 'package:wallet/wallet_assembly.dart';

typedef RpcClientFactory =
    BitcoinRpcClient Function({
      required String url,
      required String user,
      required String password,
    });

/// Composition root — wires all concrete infrastructure implementations.
///
/// Called once at startup via [create()].
final class AppDependenciesBuilder {
  final AppEnvironment _environment;
  final void Function(AppDependencies dependencies) _builder;
  final void Function(Object error, StackTrace stack) _onError;
  final RpcClientFactory _rpcClientFactory;

  AppDependenciesBuilder._({
    required AppEnvironment environment,
    required void Function(AppDependencies dependencies) builder,
    required void Function(Object error, StackTrace stack) onError,
    required RpcClientFactory rpcClientFactory,
  }) : _builder = builder,
       _environment = environment,
       _onError = onError,
       _rpcClientFactory = rpcClientFactory;

  /// Initializes the composition root and builds the app.
  ///
  /// Call this once at startup, typically in main().
  static void create({
    required AppEnvironment environment,
    required void Function(AppDependencies dependencies) builder,
    required void Function(Object error, StackTrace stack) onError,
    RpcClientFactory? rpcClientFactory,
  }) {
    final instance = AppDependenciesBuilder._(
      environment: environment,
      builder: builder,
      onError: onError,
      rpcClientFactory: rpcClientFactory ?? _defaultRpcClientFactory,
    );
    instance._build();
  }

  void _build() {
    try {
      final rpcClient = _rpcClientFactory(
        url: _environment.rpc.url,
        user: _environment.rpc.user,
        password: _environment.rpc.password,
      );
      const secureStorage = SecureStorageImpl();

      final keys = KeysAssembly(
        storage: secureStorage,
        network: _environment.network,
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

      final nodeTxDataSource = NodeTransactionDataSourceImpl(rpcClient: rpcClient);
      final blockGenDataSource = BlockGenerationDataSourceImpl(rpcClient: rpcClient);
      final broadcastDataSource = BroadcastDataSourceImpl(rpcClient: rpcClient);
      final hdAddressDataSource = HdAddressDataSourceImpl(
        repository: address.addressRepository,
      );
      final hdSigner = HdTransactionSigner(
        signTransaction: keys.signTransaction,
      );

      final transaction = TransactionAssembly(
        transactionRemoteDataSource: TransactionRemoteDataSourceImpl(rpcClient: rpcClient),
        utxoRemoteDataSource: UtxoRemoteDataSourceImpl(rpcClient: rpcClient),
        utxoScanDataSource: UtxoScanDataSourceImpl(rpcClient: rpcClient),
        broadcastDataSource: broadcastDataSource,
        nodeTransactionDataSource: nodeTxDataSource,
        blockGenerationDataSource: blockGenDataSource,
        hdAddressDataSource: hdAddressDataSource,
        coinSelectors: const [
          FifoCoinSelector(),
          LifoCoinSelector(),
          MinimizeInputsCoinSelector(),
          MinimizeChangeCoinSelector(),
        ],
        feeEstimator: const P2wpkhFeeEstimator(),
        hdSigner: hdSigner,
      );

      final dependencies = AppDependencies(
        network: _environment.network,
        keys: keys,
        wallet: wallet,
        address: address,
        transaction: transaction,
        eventBus: AppEventBus(),
      );

      _builder(dependencies);
    } catch (e, s) {
      _onError(e, s);
    }
  }

  static BitcoinRpcClient _defaultRpcClientFactory({
    required String url,
    required String user,
    required String password,
  }) => BitcoinRpcClient(
    url: url,
    user: user,
    password: password,
  );
}
