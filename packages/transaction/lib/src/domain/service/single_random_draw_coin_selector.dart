import 'dart:math';

import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/service/coin_selector_base.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// Single Random Draw (SRD) coin selector.
///
/// Randomly shuffles candidates and greedily accumulates until target + fee
/// is covered. Retries up to [_maxRetries] times with a different shuffle
/// if the first attempt fails. Introduces randomness to prevent deterministic
/// address-clustering analysis at the cost of non-reproducibility.
///
/// [isStochastic] is `true` — repeated calls may produce different results.
/// Inject [CoinSelectionRequest.random] with a seeded [Random] for tests. (G4)
final class SingleRandomDrawCoinSelector extends CoinSelectorBase {
  static const int _maxRetries = 1000;

  @override
  String get name => 'SRD';

  @override
  bool get isStochastic => true;

  // Not const — Random() is not a const constructor. (G4)
  SingleRandomDrawCoinSelector();

  @override
  CoinSelectionResult select(CoinSelectionRequest request) {
    final rng = request.random ?? Random();
    final total = request.candidates.fold(Satoshi.zero, (s, c) => s + c.amountSat);
    final maxFee = request.feeEstimator.estimateForCandidates(
      inputs: request.candidates,
      outputs: 2,
      feeRateSatPerVbyte: request.feeRateSatPerVbyte,
    );

    if (total < request.targetSat + maxFee) {
      throw InsufficientFundsException(available: total, required: request.targetSat + maxFee);
    }

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      final shuffled = List<CoinCandidate>.from(request.candidates)..shuffle(rng);
      try {
        return accumulate(sorted: shuffled, request: request);
      } on InsufficientFundsException {
        // Shuffle gave an unfortunate order — retry.
      }
    }

    // Fallback: sort by amount descending (deterministic, always succeeds if
    // total is sufficient, which was verified above).
    final fallback = List<CoinCandidate>.from(request.candidates)
      ..sort((a, b) => b.amountSat.value.compareTo(a.amountSat.value));

    return accumulate(sorted: fallback, request: request);
  }
}
