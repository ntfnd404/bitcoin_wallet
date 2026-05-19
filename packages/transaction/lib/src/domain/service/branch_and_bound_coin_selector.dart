import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/exception/coin_selection_no_solution_exception.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/service/coin_selector.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// Branch and Bound (BnB) coin selector — Bitcoin Core-style effective-value selection.
///
/// Searches for the best "changeless economic match": a set of inputs whose
/// total effective value falls in the range `[targetEffective, targetEffective + costOfChange]`,
/// where any excess below `costOfChange` is paid as additional fee rather than
/// creating an uneconomical change output.
///
/// Selection works entirely in effectiveValue space (`amountSat - inputFee`):
/// - `targetEffective = targetSat + fee(0 inputs, 1 output)`
/// - `costOfChange = (fee(0,2) - fee(0,1)) + nativeSegwitInputVbytes × feeRate`
///
/// Throws [CoinSelectionNoSolutionException] (NOT exported from barrel) when
/// no changeless economic match is found within [_defaultMaxIterations]. The
/// Prepare*UseCase catches this and omits BnB from the comparison table.
///
/// Throws [InsufficientFundsException] when the total positive effective value
/// of all candidates is less than [targetEffective].
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

    // Sort by effective satoshis descending — largest contributions first for
    // better branch pruning.
    final sorted = List<CoinCandidate>.from(request.candidates)
      ..sort((a, b) {
        final ea = a.effectiveSatoshis(feeRate, estimator.inputVbytes(a.scriptType));
        final eb = b.effectiveSatoshis(feeRate, estimator.inputVbytes(b.scriptType));

        return eb.compareTo(ea);
      });

    // Step 1: Compute effectiveValues for all sorted candidates.
    final effectiveValues = sorted
        .map((c) => c.effectiveSatoshis(feeRate, estimator.inputVbytes(c.scriptType)))
        .toList();

    // Step 2: Pre-filter to candidates with effectiveValue > 0.
    // No clamp needed — all workingEffective values are positive after filter.
    final workingCandidates = <CoinCandidate>[];
    final workingEffective = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      if (effectiveValues[i] > 0) {
        workingCandidates.add(sorted[i]);
        workingEffective.add(effectiveValues[i]);
      }
    }

    final n = workingCandidates.length;

    // Build suffix sums over filtered effective values for lower-bound pruning.
    final suffixSum = List<int>.filled(n + 1, 0);
    for (var i = n - 1; i >= 0; i--) {
      suffixSum[i] = suffixSum[i + 1] + workingEffective[i];
    }

    // Step 3: Compute thresholds.
    // targetEffective includes txOverhead + recipientOutput, matching effectiveValue
    // semantics where per-input fees are already subtracted from each candidate.
    final oneOutputFee = estimator.estimateForCandidates(
      inputs: [],
      outputs: 1,
      feeRateSatPerVbyte: feeRate,
    ).value;
    final targetEffective = request.targetSat.value + oneOutputFee;

    // costOfChange = extra change output fee + future spend fee.
    // extra change output = fee(0,2) - fee(0,1) = 31 × feeRate
    // future spend = nativeSegwit input vbytes × feeRate = 68 × feeRate
    // Total = 99 × feeRate (does not include tx overhead — already in main tx)
    final twoOutputFee = estimator.estimateForCandidates(
      inputs: [],
      outputs: 2,
      feeRateSatPerVbyte: feeRate,
    ).value;
    final costOfChange = (twoOutputFee - oneOutputFee) +
        estimator.inputVbytes(AddressType.nativeSegwit) * feeRate;

    // Step 4: InsufficientFunds check using positive effective value total.
    final totalEffective = workingEffective.fold(0, (a, b) => a + b);
    if (totalEffective < targetEffective) {
      throw InsufficientFundsException(
        available: Satoshi(totalEffective),
        required: Satoshi(targetEffective),
      );
    }

    // Step 5: DFS with upper/lower pruning. Track best solution.
    var iterations = 0;
    final selected = List<bool>.filled(n, false);

    // best tracks: [selectedEffective, inputCount, selectedMask]
    var bestExcess = -1; // -1 = no solution found yet
    var bestInputCount = n + 1;
    final bestSelected = List<bool>.filled(n, false);

    void trySearch(int depth, int effectiveAccum) {
      if (iterations >= maxIter) return;
      iterations++;

      // Upper-bound: already overshot the acceptable range — backtrack.
      if (effectiveAccum > targetEffective + costOfChange) return;

      // Lower-bound: can't reach target even with all remaining — backtrack.
      if (effectiveAccum + suffixSum[depth] < targetEffective) return;

      if (depth == n) {
        // Check success condition.
        if (effectiveAccum < targetEffective) return;

        final excess = effectiveAccum - targetEffective;
        final inputCount = selected.where((s) => s).length;

        // Update best: prefer minimum excess, then fewer inputs.
        if (bestExcess == -1 ||
            excess < bestExcess ||
            (excess == bestExcess && inputCount < bestInputCount)) {
          bestExcess = excess;
          bestInputCount = inputCount;
          for (var i = 0; i < n; i++) {
            bestSelected[i] = selected[i];
          }
        }

        return;
      }

      // Include branch.
      selected[depth] = true;
      trySearch(depth + 1, effectiveAccum + workingEffective[depth]);

      // Exclude branch.
      selected[depth] = false;
      trySearch(depth + 1, effectiveAccum);
    }

    trySearch(0, 0);

    if (bestExcess == -1) {
      throw const CoinSelectionNoSolutionException();
    }

    // Step 6: Build result from best solution.
    final selectedInputs = <CoinCandidate>[];
    for (var i = 0; i < n; i++) {
      if (bestSelected[i]) selectedInputs.add(workingCandidates[i]);
    }

    final totalRawInput = selectedInputs.fold(0, (s, c) => s + c.amountSat.value);
    final feeSat = totalRawInput - request.targetSat.value;

    // Invariant: feeSat >= fee(selectedInputs, 1 output).
    // Excess within costOfChange is intentionally paid as fee instead of
    // creating an uneconomical change output.
    return CoinSelectionResult(
      inputs: selectedInputs,
      totalInputSat: Satoshi(totalRawInput),
      feeSat: Satoshi(feeSat),
      changeSat: Satoshi.zero,
    );
  }
}
