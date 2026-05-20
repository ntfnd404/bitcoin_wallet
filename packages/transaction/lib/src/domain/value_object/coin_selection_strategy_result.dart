import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// Pairs a [CoinSelector]'s output with its strategy identity and display metadata.
final class CoinSelectionStrategyResult {
  /// Strategy name as returned by [CoinSelector.name].
  final String name;

  /// Whether results may differ between calls; mirrors [CoinSelector.isStochastic].
  final bool isStochastic;

  /// The coin-selection output produced by the strategy.
  final CoinSelectionResult result;

  const CoinSelectionStrategyResult({
    required this.name,
    required this.isStochastic,
    required this.result,
  });
}
