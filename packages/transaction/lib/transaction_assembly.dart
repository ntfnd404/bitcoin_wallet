import 'package:transaction/src/application/broadcast_transaction_use_case.dart';
import 'package:transaction/src/application/get_transaction_detail_use_case.dart';
import 'package:transaction/src/application/get_transactions_use_case.dart';
import 'package:transaction/src/application/get_utxos_use_case.dart';
import 'package:transaction/src/application/hd/prepare_hd_send_use_case.dart';
import 'package:transaction/src/application/hd/send_hd_transaction_use_case.dart';
import 'package:transaction/src/application/node/prepare_node_send_use_case.dart';
import 'package:transaction/src/application/node/send_node_transaction_use_case.dart';
import 'package:transaction/src/application/scan_utxos_use_case.dart';
import 'package:transaction/src/data/transaction_repository_impl.dart';
import 'package:transaction/src/data/utxo_repository_impl.dart';
import 'package:transaction/src/domain/data_sources/block_generation_data_source.dart';
import 'package:transaction/src/domain/data_sources/broadcast_data_source.dart';
import 'package:transaction/src/domain/data_sources/hd_address_data_source.dart';
import 'package:transaction/src/domain/data_sources/node_transaction_data_source.dart';
import 'package:transaction/src/domain/data_sources/transaction_remote_data_source.dart';
import 'package:transaction/src/domain/data_sources/utxo_remote_data_source.dart';
import 'package:transaction/src/domain/data_sources/utxo_scan_data_source.dart';
import 'package:transaction/src/domain/service/coin_selector.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/service/transaction_signer.dart';

/// Dependency injection factory for transaction and UTXO use cases.
///
/// Exposes only use cases — repositories are internal implementation details.
final class TransactionAssembly {
  final GetTransactionsUseCase getTransactions;
  final GetTransactionDetailUseCase getTransactionDetail;
  final GetUtxosUseCase getUtxos;
  final ScanUtxosUseCase scanUtxos;
  final BroadcastTransactionUseCase broadcastTransaction;
  final PrepareNodeSendUseCase prepareNodeSend;
  final PrepareHdSendUseCase prepareHdSend;
  final SendNodeTransactionUseCase sendNodeTransaction;
  final SendHdTransactionUseCase sendHdTransaction;
  final BlockGenerationDataSource blockGeneration;

  factory TransactionAssembly({
    required TransactionRemoteDataSource transactionRemoteDataSource,
    required UtxoRemoteDataSource utxoRemoteDataSource,
    required UtxoScanDataSource utxoScanDataSource,
    required BroadcastDataSource broadcastDataSource,
    required NodeTransactionDataSource nodeTransactionDataSource,
    required BlockGenerationDataSource blockGenerationDataSource,
    required HdAddressDataSource hdAddressDataSource,
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
      getTransactions: GetTransactionsUseCase(repository: txRepo),
      getTransactionDetail: GetTransactionDetailUseCase(repository: txRepo),
      getUtxos: GetUtxosUseCase(repository: utxoRepo),
      scanUtxos: ScanUtxosUseCase(dataSource: utxoScanDataSource),
      broadcastTransaction: BroadcastTransactionUseCase(
        dataSource: broadcastDataSource,
      ),
      prepareNodeSend: PrepareNodeSendUseCase(
        utxoRepository: utxoRepo,
        nodeDataSource: nodeTransactionDataSource,
        selectors: coinSelectors,
        feeEstimator: feeEstimator,
      ),
      prepareHdSend: PrepareHdSendUseCase(
        addressDataSource: hdAddressDataSource,
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
      blockGeneration: blockGenerationDataSource,
    );
  }

  const TransactionAssembly._({
    required this.getTransactions,
    required this.getTransactionDetail,
    required this.getUtxos,
    required this.scanUtxos,
    required this.broadcastTransaction,
    required this.prepareNodeSend,
    required this.prepareHdSend,
    required this.sendNodeTransaction,
    required this.sendHdTransaction,
    required this.blockGeneration,
  });
}
