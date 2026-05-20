import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/node/node_send_preparation.dart';
import 'package:transaction/src/domain/exception/coin_selection_no_solution_exception.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/node_transaction_gateway.dart';
import 'package:transaction/src/domain/repository/utxo_repository.dart';
import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/service/coin_selector.dart';
import 'package:transaction/src/domain/service/eligibility_policy.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/service/utxo_eligibility_filter.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_strategy_result.dart';

/// Fetches Node-wallet UTXOs, runs all coin-selection strategies, and returns
/// a [NodeSendPreparation] for the UI comparison table.
///
/// Does not broadcast — call [SendNodeTransactionUseCase] after confirmation.
final class PrepareNodeSendUseCase {
  final UtxoRepository _utxoRepository;
  final NodeTransactionGateway _nodeDataSource;
  final List<CoinSelector> _selectors;
  final FeeEstimator _feeEstimator;
  final UtxoEligibilityFilter _eligibilityFilter;

  const PrepareNodeSendUseCase({
    required UtxoRepository utxoRepository,
    required NodeTransactionGateway nodeDataSource,
    required List<CoinSelector> selectors,
    required FeeEstimator feeEstimator,
    UtxoEligibilityFilter eligibilityFilter = const DefaultUtxoEligibilityFilter(),
  }) : _utxoRepository = utxoRepository,
       _nodeDataSource = nodeDataSource,
       _selectors = selectors,
       _feeEstimator = feeEstimator,
       _eligibilityFilter = eligibilityFilter;

  Future<NodeSendPreparation> call({
    required String walletName,
    required Satoshi targetSat,
    required int feeRateSatPerVbyte,
  }) async {
    try {
      final utxos = await _utxoRepository.getUtxos(walletName);

      // Filter non-spendable outputs before mapping — CoinCandidate has no
      // spendable field, so this check must happen at the source (Node wallet).
      final rawCandidates = utxos
          .where((u) => u.spendable)
          .map(
            (u) => CoinCandidate(
              txid: u.txid,
              vout: u.vout,
              amountSat: u.amountSat,
              age: u.confirmations,
              scriptType: u.type,
              scriptPubKeyHex: u.scriptPubKey,
              confirmations: u.confirmations,
            ),
          )
          .toList();

      // Apply eligibility filter (confirmation count, dust/effective-value check).
      final candidates = _eligibilityFilter.filter(
        rawCandidates,
        EligibilityPolicy.node,
        _feeEstimator,
        feeRateSatPerVbyte,
      );

      final changeAddress = await _nodeDataSource.getNewAddress(walletName);

      final strategies = <CoinSelectionStrategyResult>[];
      for (final selector in _selectors) {
        try {
          strategies.add(CoinSelectionStrategyResult(
            name: selector.name,
            isStochastic: selector.isStochastic,
            result: selector.select(
              CoinSelectionRequest(
                candidates: candidates,
                targetSat: targetSat,
                feeEstimator: _feeEstimator,
                feeRateSatPerVbyte: feeRateSatPerVbyte,
                dustThreshold: _feeEstimator.dustThreshold(AddressType.nativeSegwit),
              ),
            ),
          ));
        } on InsufficientFundsException {
          // Strategy could not cover the amount — omit.
        } on CoinSelectionNoSolutionException {
          // Strategy could not cover the amount — omit from comparison table.
        }
      }

      return NodeSendPreparation(
        candidates: candidates,
        strategies: List.unmodifiable(strategies),
        changeAddress: changeAddress,
      );
    } on InsufficientFundsException {
      rethrow;
    } on TransactionException {
      rethrow;
    } on Exception catch (_, stack) {
      // 4-criteria (C1: translate infra failure to BC language, C2: n/a, C3: preserve stack, C4: typed recovery for caller).
      Error.throwWithStackTrace(const TransactionPreparationException(), stack);
    }
    // Programmer errors propagate to the zone handler.
  }
}
