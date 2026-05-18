import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/service/coin_selector_base.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// LIFO coin selector — spends the newest coins first.
///
/// Sorts by [CoinCandidate.age] ascending (lower = newer) then accumulates
/// greedily, recomputing the fee as inputs are added.
final class LifoCoinSelector extends CoinSelectorBase {
  @override
  String get name => 'LIFO';

  @override
  bool get isStochastic => false;

  const LifoCoinSelector();

  @override
  CoinSelectionResult select(CoinSelectionRequest request) {
    final sorted = [...request.candidates]..sort((a, b) => a.age.compareTo(b.age));

    return accumulate(sorted: sorted, request: request);
  }
}
