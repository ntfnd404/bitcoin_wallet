import 'package:bitcoin_node/bitcoin_node.dart';
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

      final wallet = WalletAssembly(
        storage: secureStorage,
        remoteDataSource: NodeWalletGatewayImpl(rpcClient: rpcClient),
        addressRemoteDataSource: NodeAddressGatewayImpl(rpcClient: rpcClient),
        bip39Service: keys.bip39Service,
        seedRepository: keys.seedRepository,
        keyDerivationService: keys.keyDerivationService,
      );

      final nodeTxDataSource = NodeTransactionGatewayImpl(rpcClient: rpcClient);
      final blockGenDataSource = BlockGenerationGatewayImpl(rpcClient: rpcClient);
      final broadcastDataSource = BroadcastGatewayImpl(rpcClient: rpcClient);
      final hdSigner = HdTransactionSigner(signTransaction: keys.signTransaction.call);

      final transaction = TransactionAssembly(
        transactionRemoteDataSource: TransactionHistoryGatewayImpl(rpcClient: rpcClient),
        utxoRemoteDataSource: UtxoGatewayImpl(rpcClient: rpcClient),
        utxoScanDataSource: UtxoScanGatewayImpl(rpcClient: rpcClient),
        broadcastDataSource: broadcastDataSource,
        nodeTransactionDataSource: nodeTxDataSource,
        blockGenerationDataSource: blockGenDataSource,
        addressRepository: wallet.addressRepository,
        coinSelectors: const [
          BranchAndBoundCoinSelector(),
          SmallestSingleCoinSelector(),
          FifoCoinSelector(),
          LifoCoinSelector(),
          MinimizeInputsCoinSelector(),
          MinimizeChangeCoinSelector(),
        ],
        feeEstimator: const P2wpkhFeeEstimator(),
        hdSigner: hdSigner,
      );

      _builder(
        AppDependencies(
          network: _environment.network,
          keys: keys,
          wallet: wallet,
          transaction: transaction,
          eventBus: AppEventBus(),
        ),
      );
    } catch (e, s) {
      _onError(e, s);
    }
  }

  static BitcoinRpcClient _defaultRpcClientFactory({
    required String url,
    required String user,
    required String password,
  }) => BitcoinRpcClient(url: url, user: user, password: password);
}
