import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/service/coin_selector.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// Shared greedy accumulation logic for FIFO, LIFO, and MinInputs selectors.
///
/// The accumulate loop re-estimates the fee at every step so the final fee
/// is always based on the actual number of selected inputs.
abstract base class CoinSelectorBase implements CoinSelector {
  const CoinSelectorBase();

  /// Greedy accumulation: adds coins from [sorted] until `target + fee` is
  /// covered, re-computing the fee after each addition.
  ///
  /// If the resulting change falls below [request.dustThreshold] it is folded
  /// into the fee (change output is omitted and the fee is recomputed for 1
  /// output).
  ///
  /// Throws [InsufficientFundsException] when the total is insufficient.
  CoinSelectionResult accumulate({
    required List<CoinCandidate> sorted,
    required CoinSelectionRequest request,
  }) {
    final selected = <CoinCandidate>[];
    var total = Satoshi.zero;

    for (final candidate in sorted) {
      selected.add(candidate);
      total = total + candidate.amountSat;

      final fee = request.feeEstimator.estimateForCandidates(
        inputs: selected,
        outputs: 2,
        feeRateSatPerVbyte: request.feeRateSatPerVbyte,
      );

      if (total >= request.targetSat + fee) break;
    }

    final feeSat = request.feeEstimator.estimateForCandidates(
      inputs: selected,
      outputs: 2,
      feeRateSatPerVbyte: request.feeRateSatPerVbyte,
    );

    if (total < request.targetSat + feeSat) {
      throw InsufficientFundsException(
        available: total,
        required: request.targetSat + feeSat,
      );
    }

    final rawChange = total - request.targetSat - feeSat;

    if (rawChange.value < request.dustThreshold) {
      // Fold dust into fee — single-output transaction.
      // All excess (total - target) goes to miners.
      return CoinSelectionResult(
        inputs: selected,
        totalInputSat: total,
        feeSat: total - request.targetSat,
        changeSat: Satoshi.zero,
      );
    }

    return CoinSelectionResult(
      inputs: selected,
      totalInputSat: total,
      feeSat: feeSat,
      changeSat: rawChange,
    );
  }
}
