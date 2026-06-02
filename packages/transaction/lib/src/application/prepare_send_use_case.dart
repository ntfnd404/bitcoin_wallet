import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/send_preparation.dart';
import 'package:transaction/src/domain/contract/utxo_source.dart';
import 'package:transaction/src/domain/exception/coin_selection_no_solution_exception.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/service/coin_selector.dart';
import 'package:transaction/src/domain/service/eligibility_policy.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/service/utxo_eligibility_filter.dart';
import 'package:transaction/src/domain/value_object/coin_selection_strategy_result.dart';
import 'package:transaction/src/domain/value_object/signer_payload.dart';

/// Unified prepare use case — resolves UTXOs from [UtxoSource], applies
/// eligibility filtering, runs all coin-selection strategies, and returns
/// a [SendPreparationResult] carrying the signing context for [confirm].
final class PrepareSendUseCase {
  final List<CoinSelector> _selectors;
  final FeeEstimator _feeEstimator;
  final UtxoEligibilityFilter _eligibilityFilter;

  const PrepareSendUseCase({
    required this._selectors,
    required this._feeEstimator,
    this._eligibilityFilter = const DefaultUtxoEligibilityFilter(),
  });

  Future<SendPreparation> call({
    required UtxoSource source,
    required Satoshi targetSat,
    required int feeRateSatPerVbyte,
  }) async {
    try {
      // 1. Resolve UTXOs, change address, and signing context from the source.
      final raw = await source.resolve();

      // 2. Derive eligibility policy from signing context type (Node vs HD).
      final policy = switch (raw.signingContext) {
        NodeSignerPayload() => EligibilityPolicy.node,
        HdSignerPayload() => EligibilityPolicy.hd,
      };

      // 3. Apply eligibility filter — removes dust and non-economical inputs.
      final candidates = _eligibilityFilter.filter(
        raw.candidates,
        policy,
        _feeEstimator,
        feeRateSatPerVbyte,
      );

      // 4. Run each coin-selection strategy; collect failures for UI display.
      final strategies = <CoinSelectionStrategyResult>[];
      final failedStrategies = <String>[];
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
          failedStrategies.add(selector.name);
        } on CoinSelectionNoSolutionException {
          failedStrategies.add(selector.name);
        }
      }

      // 5. Return preparation with signing context preserved for confirm step.
      return SendPreparationResult(
        strategies: List.unmodifiable(strategies),
        failedStrategies: List.unmodifiable(failedStrategies),
        changeAddress: raw.changeAddress,
        signingContext: raw.signingContext,
      );
    } on TransactionException {
      rethrow;
    } on Exception catch (_, stack) {
      Error.throwWithStackTrace(const TransactionPreparationException(), stack);
    }
  }
}
