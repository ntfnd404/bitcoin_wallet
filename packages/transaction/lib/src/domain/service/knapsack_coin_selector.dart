import 'dart:math';

import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/service/coin_selector_base.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// Knapsack (stochastic subset-sum) coin selector — legacy Bitcoin Core approach.
///
/// Makes up to [_maxTrials] random attempts to find an exact or near-exact
/// subset sum, then falls back to a greedy largest-first accumulation. This
/// was Bitcoin Core's primary algorithm before Branch-and-Bound was introduced
/// in 2017. Retained here for educational comparison.
///
/// [isStochastic] is `true` — results may differ between calls. Inject
/// [CoinSelectionRequest.random] with a seeded [Random] for tests. (G4)
final class KnapsackCoinSelector extends CoinSelectorBase {
  static const int _maxTrials = 1000;

  @override
  String get name => 'Knapsack';

  @override
  bool get isStochastic => true;

  // Not const — Random() is not a const constructor. (G4)
  KnapsackCoinSelector();

  @override
  CoinSelectionResult select(CoinSelectionRequest request) {
    final rng = request.random ?? Random();
    final feeRate = request.feeRateSatPerVbyte;
    final estimator = request.feeEstimator;
    final candidates = request.candidates;

    final totalAvail = candidates.fold(Satoshi.zero, (s, c) => s + c.amountSat);
    final worstFee = estimator.estimateForCandidates(
      inputs: candidates,
      outputs: 2,
      feeRateSatPerVbyte: feeRate,
    );
    if (totalAvail < request.targetSat + worstFee) {
      throw InsufficientFundsException(
        available: totalAvail,
        required: request.targetSat + worstFee,
      );
    }

    // Trial phase: random shuffles looking for near-exact match.
    for (var trial = 0; trial < _maxTrials; trial++) {
      final shuffled = List<CoinCandidate>.from(candidates)..shuffle(rng);
      var trialTotal = Satoshi.zero;
      final selected = <CoinCandidate>[];

      for (final c in shuffled) {
        selected.add(c);
        trialTotal = trialTotal + c.amountSat;

        final fee = estimator.estimateForCandidates(
          inputs: selected,
          outputs: 1, // try no-change first
          feeRateSatPerVbyte: feeRate,
        );

        if (trialTotal.value == request.targetSat.value + fee.value) {
          // Exact match found — zero-change transaction.
          return CoinSelectionResult(
            inputs: selected,
            totalInputSat: trialTotal,
            feeSat: fee,
            changeSat: Satoshi.zero,
          );
        }

        final feeWith2Out = estimator.estimateForCandidates(
          inputs: selected,
          outputs: 2,
          feeRateSatPerVbyte: feeRate,
        );
        if (trialTotal >= request.targetSat + feeWith2Out) break;
      }
    }

    // Fallback: greedy largest-first accumulation with change output.
    final sorted = List<CoinCandidate>.from(candidates)
      ..sort((a, b) => b.amountSat.value.compareTo(a.amountSat.value));

    return accumulate(sorted: sorted, request: request);
  }
}
