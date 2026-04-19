import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/service/coin_selector.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// MinChange coin selector — minimises the change output.
///
/// Sorts candidates by amount descending and tries every non-empty prefix,
/// keeping the result with the smallest non-dust change. Capped at 20
/// candidates to bound complexity.
final class MinimizeChangeCoinSelector implements CoinSelector {
  static const int _cap = 20;

  @override
  String get name => 'MinChange';

  const MinimizeChangeCoinSelector();

  @override
  CoinSelectionResult select({
    required List<CoinCandidate> candidates,
    required Satoshi targetSat,
    required FeeEstimator feeEstimator,
    required int feeRateSatPerVbyte,
    required int dustThreshold,
  }) {
    final pool = (candidates.length > _cap
            ? (candidates.toList()
              ..sort((a, b) => b.amountSat.value.compareTo(a.amountSat.value)))
                .take(_cap)
                .toList()
            : candidates.toList())
      ..sort((a, b) => b.amountSat.value.compareTo(a.amountSat.value));

    final poolTotal = pool.fold(Satoshi.zero, (s, c) => s + c.amountSat);
    final maxFee = feeEstimator.estimate(
      inputs: pool.length,
      outputs: 2,
      feeRateSatPerVbyte: feeRateSatPerVbyte,
    );

    if (poolTotal < targetSat + maxFee) {
      throw InsufficientFundsException(
        available: poolTotal,
        required: targetSat + maxFee,
      );
    }

    CoinSelectionResult? best;

    for (var k = 1; k <= pool.length; k++) {
      final subset = pool.sublist(0, k);
      final total = subset.fold(Satoshi.zero, (s, c) => s + c.amountSat);

      final feeSat = feeEstimator.estimate(
        inputs: k,
        outputs: 2,
        feeRateSatPerVbyte: feeRateSatPerVbyte,
      );

      if (total < targetSat + feeSat) continue;

      final rawChange = total - targetSat - feeSat;

      final CoinSelectionResult result;
      if (rawChange.value < dustThreshold) {
        result = CoinSelectionResult(
          inputs: subset,
          totalInputSat: total,
          feeSat: total - targetSat,
          changeSat: Satoshi.zero,
        );
      } else {
        result = CoinSelectionResult(
          inputs: subset,
          totalInputSat: total,
          feeSat: feeSat,
          changeSat: rawChange,
        );
      }

      if (best == null || result.changeSat.value < best.changeSat.value) {
        best = result;
      }

      if (result.changeSat == Satoshi.zero) break;
    }

    return best!;
  }
}
