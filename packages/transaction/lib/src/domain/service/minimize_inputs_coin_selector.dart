import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/service/coin_selector_base.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// MinInputs coin selector — minimises the number of inputs.
///
/// Sorts by [CoinCandidate.amountSat] descending (largest first) so that the
/// fewest coins are needed to cover `target + fee`.
final class MinimizeInputsCoinSelector extends CoinSelectorBase {
  @override
  String get name => 'MinInputs';

  @override
  bool get isStochastic => false;

  const MinimizeInputsCoinSelector();

  @override
  CoinSelectionResult select(CoinSelectionRequest request) {
    final sorted = [...request.candidates]
      ..sort((a, b) => b.amountSat.value.compareTo(a.amountSat.value));

    return accumulate(sorted: sorted, request: request);
  }
}
