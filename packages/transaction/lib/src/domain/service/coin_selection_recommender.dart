import 'package:transaction/src/domain/value_object/coin_selection_result.dart';
import 'package:transaction/src/domain/value_object/coin_selection_strategy_result.dart';

/// Picks the recommended coin-selection strategy from a set of computed results.
abstract interface class CoinSelectionRecommender {
  String? recommend(
    List<CoinSelectionStrategyResult> strategies,
    int feeRateSatPerVbyte,
  );
}

/// Default implementation using a pragmatic waste score.
///
/// Sort order (each tie-breaker applied if previous is equal):
/// 1. `_score` ascending — lower waste is better
/// 2. `inputs.length` ascending — fewer inputs = smaller tx
/// 3. `changeSat` ascending — less change = simpler UTXO set
/// 4. Original list position — stable tie-breaker (G8)
final class DefaultCoinSelectionRecommender implements CoinSelectionRecommender {
  const DefaultCoinSelectionRecommender();

  @override
  String? recommend(
    List<CoinSelectionStrategyResult> strategies,
    int feeRateSatPerVbyte,
  ) {
    if (strategies.isEmpty) return null;

    final indexed = strategies.indexed.toList();
    indexed.sort((a, b) {
      final aScore = _score(a.$2.result, feeRateSatPerVbyte);
      final bScore = _score(b.$2.result, feeRateSatPerVbyte);

      final scoreDiff = aScore.compareTo(bScore);
      if (scoreDiff != 0) return scoreDiff;

      final inputsDiff =
          a.$2.result.inputs.length.compareTo(b.$2.result.inputs.length);
      if (inputsDiff != 0) return inputsDiff;

      final changeDiff =
          a.$2.result.changeSat.value.compareTo(b.$2.result.changeSat.value);
      if (changeDiff != 0) return changeDiff;

      return a.$1.compareTo(b.$1);
    });

    return indexed.first.$2.name;
  }

  // waste = feeSat + cost of a 68-vbyte P2WPKH change output (if any).
  // changeSat == 0 means dust was folded into the fee — no change output created.
  int _score(CoinSelectionResult result, int feeRateSatPerVbyte) =>
      result.feeSat.value +
      (result.changeSat.value > 0 ? 68 * feeRateSatPerVbyte : 0);
}
