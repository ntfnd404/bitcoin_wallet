import 'dart:math';

import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';

/// Encapsulates all parameters needed by a [CoinSelector].
///
/// Using a request object keeps the [CoinSelector.select] signature stable
/// as new parameters are added (SOLID/KISS). Stochastic selectors use
/// [random]; deterministic selectors ignore it.
final class CoinSelectionRequest {
  final List<CoinCandidate> candidates;
  final Satoshi targetSat;
  final int feeRateSatPerVbyte;
  final FeeEstimator feeEstimator;
  final int dustThreshold;

  /// Injected [Random] instance for stochastic selectors (SRD, Knapsack).
  /// Deterministic selectors must ignore this field. (G4: injectable for tests)
  final Random? random;

  /// Maximum number of iterations for bounded-search selectors (BnB, Knapsack).
  /// `null` means the selector uses its own built-in default.
  final int? maxIterations;

  const CoinSelectionRequest({
    required this.candidates,
    required this.targetSat,
    required this.feeRateSatPerVbyte,
    required this.feeEstimator,
    required this.dustThreshold,
    this.random,
    this.maxIterations,
  });
}
