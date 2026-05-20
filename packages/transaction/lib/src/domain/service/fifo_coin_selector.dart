import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/service/coin_selector_base.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// FIFO coin selector — spends the oldest coins first.
///
/// Sorts by [CoinCandidate.age] descending (higher = older) then accumulates
/// greedily, recomputing the fee as inputs are added.
final class FifoCoinSelector extends CoinSelectorBase {
  @override
  String get name => 'FIFO';

  @override
  bool get isStochastic => false;

  const FifoCoinSelector();

  @override
  CoinSelectionResult select(CoinSelectionRequest request) {
    final sorted = [...request.candidates]..sort((a, b) => b.age.compareTo(a.age));

    return accumulate(sorted: sorted, request: request);
  }
}
