import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// Strategy interface for selecting UTXOs to fund a transaction (GoF Strategy).
///
/// [FeeEstimator] and [feeRateSatPerVbyte] are passed in so each implementation
/// can compute the correct fee as the input count grows during accumulation.
///
/// All implementations throw [InsufficientFundsException] when no valid
/// selection exists.
abstract interface class CoinSelector {
  /// Human-readable strategy name shown in the UI comparison table.
  String get name;

  /// Selects coins from [candidates] sufficient to cover [targetSat] + fee.
  ///
  /// [feeEstimator] and [feeRateSatPerVbyte] are used to compute the fee
  /// incrementally as inputs are added.
  ///
  /// [dustThreshold] — change below this amount (sat) is folded into the fee.
  CoinSelectionResult select({
    required List<CoinCandidate> candidates,
    required Satoshi targetSat,
    required FeeEstimator feeEstimator,
    required int feeRateSatPerVbyte,
    required int dustThreshold,
  });
}
