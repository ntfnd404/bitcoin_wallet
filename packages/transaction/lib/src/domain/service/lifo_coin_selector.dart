import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/service/coin_selector_base.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// LIFO coin selector — spends the newest coins first.
///
/// Sorts by [CoinCandidate.age] ascending (lower = newer) then accumulates
/// greedily, recomputing the fee as inputs are added.
final class LifoCoinSelector extends CoinSelectorBase {
  @override
  String get name => 'LIFO';

  const LifoCoinSelector();

  @override
  CoinSelectionResult select({
    required List<CoinCandidate> candidates,
    required Satoshi targetSat,
    required FeeEstimator feeEstimator,
    required int feeRateSatPerVbyte,
    required int dustThreshold,
  }) {
    final sorted = [...candidates]..sort((a, b) => a.age.compareTo(b.age));

    return accumulate(
      sorted: sorted,
      targetSat: targetSat,
      feeEstimator: feeEstimator,
      feeRateSatPerVbyte: feeRateSatPerVbyte,
      dustThreshold: dustThreshold,
    );
  }
}
