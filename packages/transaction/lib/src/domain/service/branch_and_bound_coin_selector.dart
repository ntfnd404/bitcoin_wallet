import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/exception/coin_selection_no_solution_exception.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/service/coin_selector.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// Branch and Bound (BnB) coin selector (Pieter Wuille, Bitcoin Core 2017).
///
/// Searches for an exact-match subset: a set of inputs whose total equals
/// `recipientAmount + fee(inputs, outputs=1)` exactly, producing a
/// zero-change transaction. This minimises the UTXO set and avoids creating
/// change outputs.
///
/// Throws [CoinSelectionNoSolutionException] (NOT exported from barrel) when
/// no exact match is found within [_maxIterations]. The Prepare*UseCase catches
/// this and omits BnB from the comparison table — funds are sufficient, but
/// no zero-change combination exists.
///
/// Throws [InsufficientFundsException] when the total available balance is
/// less than the required amount.
///
/// [isStochastic] is `false`.
///
/// References:
/// - https://bitcoincore.reviews/17526
/// - https://bitcoincore.academy/coin-selection.html
final class BranchAndBoundCoinSelector implements CoinSelector {
  static const int _defaultMaxIterations = 100000;

  @override
  String get name => 'BnB';

  @override
  bool get isStochastic => false;

  const BranchAndBoundCoinSelector();

  @override
  CoinSelectionResult select(CoinSelectionRequest request) {
    final maxIter = request.maxIterations ?? _defaultMaxIterations;
    final feeRate = request.feeRateSatPerVbyte;
    final estimator = request.feeEstimator;

    // Sort by effective satoshis descending — largest contributions first
    // for better branch pruning.
    final sorted = List<CoinCandidate>.from(request.candidates)
      ..sort((a, b) {
        final ea = a.effectiveSatoshis(feeRate, estimator.inputVbytes(a.scriptType));
        final eb = b.effectiveSatoshis(feeRate, estimator.inputVbytes(b.scriptType));

        return eb.compareTo(ea);
      });

    final totalAvailable = sorted.fold(Satoshi.zero, (s, c) => s + c.amountSat);

    // Worst-case fee with all inputs, used for early InsufficientFunds check.
    final maxFee = estimator.estimateForCandidates(
      inputs: sorted,
      outputs: 2,
      feeRateSatPerVbyte: feeRate,
    );
    if (totalAvailable < request.targetSat + maxFee) {
      throw InsufficientFundsException(
        available: totalAvailable,
        required: request.targetSat + maxFee,
      );
    }

    // Suffix sums for pruning — sum of all candidates from index i to end.
    final n = sorted.length;
    final suffixSum = List<int>.filled(n + 1, 0);
    for (var i = n - 1; i >= 0; i--) {
      suffixSum[i] = suffixSum[i + 1] + sorted[i].amountSat.value;
    }

    var iterations = 0;
    final selected = List<bool>.filled(n, false);

    CoinSelectionResult? trySearch(int depth, int currentTotal) {
      iterations++;
      if (iterations > maxIter) return null;

      if (depth == n) {
        if (currentTotal == 0) return null; // empty set
        final inputs = <CoinCandidate>[];
        for (var i = 0; i < n; i++) {
          if (selected[i]) inputs.add(sorted[i]);
        }
        final fee = estimator.estimateForCandidates(
          inputs: inputs,
          outputs: 1, // no change output
          feeRateSatPerVbyte: feeRate,
        );
        final target = request.targetSat.value + fee.value;
        if (currentTotal == target) {
          return CoinSelectionResult(
            inputs: inputs,
            totalInputSat: Satoshi(currentTotal),
            feeSat: fee,
            changeSat: Satoshi.zero,
          );
        }

        return null;
      }

      // Pruning: even adding all remaining candidates can't reach target.
      // Use a rough target estimate for pruning (1-output fee, lower bound).
      final roughFee = estimator.estimateForCandidates(
        inputs: [sorted[depth]], // minimum 1 input
        outputs: 1,
        feeRateSatPerVbyte: feeRate,
      );
      final minTarget = request.targetSat.value + roughFee.value;
      if (currentTotal + suffixSum[depth] < minTarget) return null;

      // Include branch.
      selected[depth] = true;
      final withResult = trySearch(depth + 1, currentTotal + sorted[depth].amountSat.value);
      if (withResult != null) return withResult;

      // Exclude branch.
      selected[depth] = false;

      return trySearch(depth + 1, currentTotal);
    }

    final result = trySearch(0, 0);

    if (result == null) {
      throw const CoinSelectionNoSolutionException();
    }

    return result;
  }
}
