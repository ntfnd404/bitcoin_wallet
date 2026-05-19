import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/service/coin_selector.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// MinChange coin selector — minimises the change output.
///
/// Performs an exhaustive 2^N search over all non-empty subsets when N ≤ 20,
/// keeping the result with the smallest change. Zero-change includes both true
/// exact matches and dust-folded results (rawChange < dustThreshold); these are
/// broken by feeSat then inputs.length. For N > 20 the pool is reduced to the
/// top-20 candidates by effective satoshis — this is a documented heuristic
/// that may miss optimal subsets composed of small coins.
final class MinimizeChangeCoinSelector implements CoinSelector {
  static const int _cap = 20;

  @override
  String get name => 'MinChange';

  @override
  bool get isStochastic => false;

  const MinimizeChangeCoinSelector();

  @override
  CoinSelectionResult select(CoinSelectionRequest request) {
    final pool = _buildPool(request);

    if (pool.isEmpty) {
      throw InsufficientFundsException(
        available: Satoshi.zero,
        required: request.targetSat,
      );
    }

    final poolTotal = pool.fold(Satoshi.zero, (s, c) => s + c.amountSat);
    final n = pool.length;

    CoinSelectionResult? best;

    for (var mask = 1; mask < (1 << n); mask++) {
      final subset = <CoinCandidate>[];
      for (var bit = 0; bit < n; bit++) {
        if (mask & (1 << bit) != 0) subset.add(pool[bit]);
      }

      final total = subset.fold(Satoshi.zero, (s, c) => s + c.amountSat);
      final feeSat = request.feeEstimator.estimateForCandidates(
        inputs: subset,
        outputs: 2,
        feeRateSatPerVbyte: request.feeRateSatPerVbyte,
      );

      if (total < request.targetSat + feeSat) continue;

      final rawChange = total - request.targetSat - feeSat;
      final CoinSelectionResult result;

      if (rawChange.value < request.dustThreshold) {
        result = CoinSelectionResult(
          inputs: subset,
          totalInputSat: total,
          feeSat: total - request.targetSat,
          changeSat: Satoshi.zero,
        );
      } else {
        result = CoinSelectionResult(
          inputs: subset,
          totalInputSat: total,
          feeSat: feeSat,
          changeSat: rawChange,
        );
      }

      if (best == null || _isBetter(result, best)) {
        best = result;
      }
    }

    if (best == null) {
      throw InsufficientFundsException(
        available: poolTotal,
        required: request.targetSat,
      );
    }

    return best;
  }

  bool _isBetter(CoinSelectionResult candidate, CoinSelectionResult current) {
    if (candidate.changeSat.value != current.changeSat.value) {
      return candidate.changeSat.value < current.changeSat.value;
    }
    if (candidate.feeSat.value != current.feeSat.value) {
      return candidate.feeSat.value < current.feeSat.value;
    }

    return candidate.inputs.length < current.inputs.length;
  }

  /// Builds the candidate pool. If candidates ≤ _cap, uses all. Otherwise,
  /// takes the top-_cap by effective satoshis descending (heuristic — may
  /// miss optimal subsets of small UTXOs, documented in conventions).
  List<CoinCandidate> _buildPool(CoinSelectionRequest request) {
    if (request.candidates.length <= _cap) return request.candidates;

    final feeRate = request.feeRateSatPerVbyte;
    final estimator = request.feeEstimator;

    return (List<CoinCandidate>.from(request.candidates)
          ..sort(
            (a, b) => b
                .effectiveSatoshis(feeRate, estimator.inputVbytes(b.scriptType))
                .compareTo(a.effectiveSatoshis(feeRate, estimator.inputVbytes(a.scriptType))),
          ))
        .take(_cap)
        .toList();
  }
}
