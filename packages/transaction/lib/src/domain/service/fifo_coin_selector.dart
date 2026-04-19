import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/service/coin_selector_base.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// FIFO coin selector — spends the oldest coins first.
///
/// Sorts by [CoinCandidate.age] descending (higher = older) then accumulates
/// greedily, recomputing the fee as inputs are added.
final class FifoCoinSelector extends CoinSelectorBase {
  @override
  String get name => 'FIFO';

  const FifoCoinSelector();

  @override
  CoinSelectionResult select({
    required List<CoinCandidate> candidates,
    required Satoshi targetSat,
    required FeeEstimator feeEstimator,
    required int feeRateSatPerVbyte,
    required int dustThreshold,
  }) {
    final sorted = [...candidates]..sort((a, b) => b.age.compareTo(a.age));

    return accumulate(
      sorted: sorted,
      targetSat: targetSat,
      feeEstimator: feeEstimator,
      feeRateSatPerVbyte: feeRateSatPerVbyte,
      dustThreshold: dustThreshold,
    );
  }
}
