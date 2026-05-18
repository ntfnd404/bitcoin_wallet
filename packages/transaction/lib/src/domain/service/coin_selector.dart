import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// Strategy interface for selecting UTXOs to fund a transaction (GoF Strategy).
///
/// All parameters are encapsulated in [CoinSelectionRequest] so the interface
/// signature stays stable as new parameters are added (SOLID/KISS).
///
/// Implementations throw [InsufficientFundsException] when no valid
/// selection exists.
abstract interface class CoinSelector {
  /// Human-readable strategy name shown in the UI comparison table.
  String get name;

  /// Whether this selector produces non-deterministic results.
  ///
  /// Stochastic selectors (SRD, Knapsack) may return different results on
  /// repeated calls. The UI shows an indicator so users understand that
  /// recalculating may change the result. (G9)
  bool get isStochastic;

  /// Selects coins from [request.candidates] sufficient to cover
  /// [request.targetSat] + fee.
  ///
  /// Throws [InsufficientFundsException] when the total available balance
  /// cannot cover the requested amount.
  CoinSelectionResult select(CoinSelectionRequest request);
}
