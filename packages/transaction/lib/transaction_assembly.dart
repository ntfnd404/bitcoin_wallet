import 'package:transaction/src/application/hd/prepare_hd_send_use_case.dart';
import 'package:transaction/src/application/hd/send_hd_transaction_use_case.dart';
import 'package:transaction/src/application/node/prepare_node_pinned_send_use_case.dart';
import 'package:transaction/src/application/node/prepare_node_send_use_case.dart';
import 'package:transaction/src/application/node/send_node_transaction_use_case.dart';
import 'package:transaction/src/application/node/send_op_return_use_case.dart';
import 'package:transaction/src/data/repository/transaction_repository_impl.dart';
import 'package:transaction/src/data/repository/utxo_repository_impl.dart';
import 'package:transaction/src/domain/gateway/block_generation_gateway.dart';
import 'package:transaction/src/domain/gateway/broadcast_gateway.dart';
import 'package:transaction/src/domain/gateway/node_transaction_gateway.dart';
import 'package:transaction/src/domain/gateway/transaction_history_gateway.dart';
import 'package:transaction/src/domain/gateway/utxo_gateway.dart';
import 'package:transaction/src/domain/gateway/utxo_scan_gateway.dart';
import 'package:transaction/src/domain/repository/transaction_repository.dart';
import 'package:transaction/src/domain/repository/utxo_repository.dart';
import 'package:transaction/src/domain/service/coin_selector.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/service/transaction_signer.dart';
import 'package:wallet/wallet.dart';

/// Dependency injection factory for the transaction bounded context.
///
/// Exposes repositories, gateways, and use cases for direct use by BLoCs.
/// Use cases that contain no logic beyond delegation are not wrapped here.
final class TransactionAssembly {
  final TransactionRepository transactionRepository;
  final UtxoRepository utxoRepository;
  final UtxoScanGateway utxoScanGateway;
  final BroadcastGateway broadcastGateway;
  final BlockGenerationGateway blockGenerationGateway;

  /// Fee estimator — exposed for features that need fee estimation outside
  /// of a send use case (e.g. the UTXO picker running total).
  final FeeEstimator feeEstimator;

  final PrepareNodeSendUseCase prepareNodeSend;
  final PrepareNodePinnedSendUseCase prepareNodePinnedSend;
  final PrepareHdSendUseCase prepareHdSend;
  final SendNodeTransactionUseCase sendNodeTransaction;
  final SendHdTransactionUseCase sendHdTransaction;
  final SendOpReturnUseCase sendOpReturn;

  factory TransactionAssembly({
    required TransactionHistoryGateway transactionRemoteDataSource,
    required UtxoGateway utxoRemoteDataSource,
    required UtxoScanGateway utxoScanDataSource,
    required BroadcastGateway broadcastDataSource,
    required NodeTransactionGateway nodeTransactionDataSource,
    required BlockGenerationGateway blockGenerationDataSource,
    required AddressRepository addressRepository,
    required List<CoinSelector> coinSelectors,
    required FeeEstimator feeEstimator,
    required TransactionSigner hdSigner,
  }) {
    final txRepo = TransactionRepositoryImpl(
      remoteDataSource: transactionRemoteDataSource,
    );
    final utxoRepo = UtxoRepositoryImpl(
      remoteDataSource: utxoRemoteDataSource,
    );

    return TransactionAssembly._(
      transactionRepository: txRepo,
      utxoRepository: utxoRepo,
      utxoScanGateway: utxoScanDataSource,
      broadcastGateway: broadcastDataSource,
      blockGenerationGateway: blockGenerationDataSource,
      feeEstimator: feeEstimator,
      prepareNodeSend: PrepareNodeSendUseCase(
        utxoRepository: utxoRepo,
        nodeDataSource: nodeTransactionDataSource,
        selectors: coinSelectors,
        feeEstimator: feeEstimator,
      ),
      prepareNodePinnedSend: PrepareNodePinnedSendUseCase(
        nodeDataSource: nodeTransactionDataSource,
        selectors: coinSelectors,
        feeEstimator: feeEstimator,
      ),
      prepareHdSend: PrepareHdSendUseCase(
        addressRepository: addressRepository,
        utxoScanDataSource: utxoScanDataSource,
        selectors: coinSelectors,
        feeEstimator: feeEstimator,
      ),
      sendNodeTransaction: SendNodeTransactionUseCase(
        nodeDataSource: nodeTransactionDataSource,
        broadcastDataSource: broadcastDataSource,
      ),
      sendHdTransaction: SendHdTransactionUseCase(
        signer: hdSigner,
        broadcastDataSource: broadcastDataSource,
      ),
      sendOpReturn: SendOpReturnUseCase(
        utxoRepository: utxoRepo,
        nodeDataSource: nodeTransactionDataSource,
        broadcastDataSource: broadcastDataSource,
        feeEstimator: feeEstimator,
      ),
    );
  }

  const TransactionAssembly._({
    required this.transactionRepository,
    required this.utxoRepository,
    required this.utxoScanGateway,
    required this.broadcastGateway,
    required this.blockGenerationGateway,
    required this.feeEstimator,
    required this.prepareNodeSend,
    required this.prepareNodePinnedSend,
    required this.prepareHdSend,
    required this.sendNodeTransaction,
    required this.sendHdTransaction,
    required this.sendOpReturn,
  });
}
