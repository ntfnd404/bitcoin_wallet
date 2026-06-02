import 'package:transaction/src/application/node/send_op_return_use_case.dart';
import 'package:transaction/src/application/prepare_send_use_case.dart';
import 'package:transaction/src/application/send_workflow.dart';
import 'package:transaction/src/application/send_workflow_impl.dart';
import 'package:transaction/src/application/signer/hd_in_app_signer.dart';
import 'package:transaction/src/application/signer/node_rpc_signer.dart';
import 'package:transaction/src/application/source/hd_auto_utxo_source.dart';
import 'package:transaction/src/application/source/hd_pinned_utxo_source.dart';
import 'package:transaction/src/application/source/node_auto_utxo_source.dart';
import 'package:transaction/src/application/source/node_pinned_utxo_source.dart';
import 'package:transaction/src/data/repository/transaction_repository_impl.dart';
import 'package:transaction/src/data/repository/utxo_repository_impl.dart';
import 'package:transaction/src/domain/contract/signer.dart';
import 'package:transaction/src/domain/contract/utxo_source.dart';
import 'package:transaction/src/domain/entity/utxo.dart';
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
import 'package:transaction/src/domain/service/utxo_eligibility_filter.dart';
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

  final SendOpReturnUseCase sendOpReturn;

  /// Exposed for features that need direct address generation (e.g. regtest mining).
  final NodeTransactionGateway nodeTransactionGateway;
  final AddressRepository _addressRepository;
  final TransactionSigner _hdSigner;
  final String _bech32Hrp;
  final List<CoinSelector> _coinSelectors;

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
    required String bech32Hrp,
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
      nodeTransactionGateway: nodeTransactionDataSource,
      addressRepository: addressRepository,
      hdSigner: hdSigner,
      bech32Hrp: bech32Hrp,
      coinSelectors: List.unmodifiable(coinSelectors),
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
    required this.nodeTransactionGateway,
    required this._addressRepository,
    required this._hdSigner,
    required this._bech32Hrp,
    required this._coinSelectors,
    required this.sendOpReturn,
  });

  /// Builds a [SendWorkflow] for auto coin-selection.
  ///
  /// Composes: wallet-flavour [UtxoSource] → [PrepareSendUseCase] (eligibility
  /// filter + all selectors) → wallet-flavour [Signer] → [SendWorkflowImpl].
  /// The wallet-type switch is confined to [_autoSourceFor] and [_signerFor].
  SendWorkflow buildAutoSendWorkflow(Wallet wallet) => SendWorkflowImpl(
        source: _autoSourceFor(wallet),
        signer: _signerFor(wallet),
        prepare: PrepareSendUseCase(
          selectors: _coinSelectors,
          feeEstimator: feeEstimator,
        ),
      );

  /// Builds a [SendWorkflow] for manual (caller-pinned) coin selection.
  ///
  /// Uses [PinnedUtxoEligibilityFilter] instead of [DefaultUtxoEligibilityFilter]:
  /// the user explicitly selected these inputs, so confirmation policy is skipped.
  /// Dust inputs are still rejected (effectiveSatoshis ≤ 0).
  SendWorkflow buildPinnedSendWorkflow(Wallet wallet, List<Utxo> pinned) => SendWorkflowImpl(
        source: _pinnedSourceFor(wallet, pinned),
        signer: _signerFor(wallet),
        prepare: PrepareSendUseCase(
          selectors: _coinSelectors,
          feeEstimator: feeEstimator,
          eligibilityFilter: const PinnedUtxoEligibilityFilter(),
        ),
      );

  // Node → NodeAutoUtxoSource (fetches from UtxoRepository + Bitcoin Core).
  // HD   → HdAutoUtxoSource  (scans addresses via UtxoScanGateway).
  UtxoSource _autoSourceFor(Wallet wallet) => switch (wallet) {
        final NodeWallet w => NodeAutoUtxoSource(
            walletName: w.name,
            utxoRepository: utxoRepository,
            nodeTransactionGateway: nodeTransactionGateway,
          ),
        final HdWallet w => HdAutoUtxoSource(
            walletId: w.id,
            addressRepository: _addressRepository,
            utxoScanGateway: utxoScanGateway,
          ),
      };

  // Node → NodePinnedUtxoSource (passes pinned inputs through, no filter).
  // HD   → HdPinnedUtxoSource  (resolves each pinned address to SigningInput).
  UtxoSource _pinnedSourceFor(Wallet wallet, List<Utxo> pinned) => switch (wallet) {
        final NodeWallet w => NodePinnedUtxoSource(
            walletName: w.name,
            pinnedInputs: pinned,
            nodeTransactionGateway: nodeTransactionGateway,
          ),
        final HdWallet w => HdPinnedUtxoSource(
            walletId: w.id,
            pinnedInputs: pinned,
            addressRepository: _addressRepository,
          ),
      };

  // Node → NodeRpcSigner (signs via signrawtransactionwithwallet, broadcasts).
  // HD   → HdInAppSigner (derives keys in-app, signs, broadcasts).
  Signer _signerFor(Wallet wallet) => switch (wallet) {
        final NodeWallet w => NodeRpcSigner(
            walletName: w.name,
            nodeTransactionGateway: nodeTransactionGateway,
            broadcastGateway: broadcastGateway,
          ),
        final HdWallet w => HdInAppSigner(
            walletId: w.id,
            bech32Hrp: _bech32Hrp,
            transactionSigner: _hdSigner,
            broadcastGateway: broadcastGateway,
          ),
      };
}
