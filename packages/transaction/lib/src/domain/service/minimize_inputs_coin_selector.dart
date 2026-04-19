import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/service/coin_selector_base.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// MinInputs coin selector — minimises the number of inputs.
///
/// Sorts by [CoinCandidate.amountSat] descending (largest first) so that the
/// fewest coins are needed to cover `target + fee`.
final class MinimizeInputsCoinSelector extends CoinSelectorBase {
  @override
  String get name => 'MinInputs';

  const MinimizeInputsCoinSelector();

  @override
  CoinSelectionResult select({
    required List<CoinCandidate> candidates,
    required Satoshi targetSat,
    required FeeEstimator feeEstimator,
    required int feeRateSatPerVbyte,
    required int dustThreshold,
  }) {
    final sorted = [...candidates]
      ..sort((a, b) => b.amountSat.value.compareTo(a.amountSat.value));

    return accumulate(
      sorted: sorted,
      targetSat: targetSat,
      feeEstimator: feeEstimator,
      feeRateSatPerVbyte: feeRateSatPerVbyte,
      dustThreshold: dustThreshold,
    );
  }
}
