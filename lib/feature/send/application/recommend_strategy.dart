import 'package:transaction/transaction.dart';

/// Picks the recommended coin-selection strategy from a set of computed results.
///
/// Sort order (each tie-breaker applied if previous is equal):
/// 1. `feeSat` ascending — cheaper is better
/// 2. `inputs.length` ascending — fewer inputs = smaller future UTXO set
/// 3. `changeSat` ascending — less change = simpler UTXO set
/// 4. Original Map insertion order — explicit index, since Dart `List.sort` is NOT stable (G8)
///
/// Returns `null` when `strategies` is empty. Caller must handle this case.
String? recommendStrategy(Map<String, CoinSelectionResult> strategies) {
  if (strategies.isEmpty) return null;

  final indexed = <(int, MapEntry<String, CoinSelectionResult>)>[];
  var idx = 0;
  for (final entry in strategies.entries) {
    indexed.add((idx, entry));
    idx++;
  }

  indexed.sort((a, b) {
    final aResult = a.$2.value;
    final bResult = b.$2.value;

    final feeDiff = aResult.feeSat.value.compareTo(bResult.feeSat.value);
    if (feeDiff != 0) return feeDiff;

    final inputsDiff = aResult.inputs.length.compareTo(bResult.inputs.length);
    if (inputsDiff != 0) return inputsDiff;

    final changeDiff = aResult.changeSat.value.compareTo(bResult.changeSat.value);
    if (changeDiff != 0) return changeDiff;

    return a.$1.compareTo(b.$1);
  });

  return indexed.first.$2.key;
}
