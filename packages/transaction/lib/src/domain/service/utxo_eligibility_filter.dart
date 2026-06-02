import 'package:transaction/src/domain/service/eligibility_policy.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';

/// Filters [CoinCandidate]s before they reach any [CoinSelector].
///
/// Removes candidates that:
/// - have unknown confirmations when [EligibilityPolicy.allowUnknownConfirmations] is false
/// - have fewer confirmations than [EligibilityPolicy.minConfirmations]
/// - have `effectiveSatoshis ≤ 0` (cost to spend ≥ value) — G5
abstract interface class UtxoEligibilityFilter {
  List<CoinCandidate> filter(
    List<CoinCandidate> candidates,
    EligibilityPolicy policy,
    FeeEstimator feeEstimator,
    int feeRateSatPerVbyte,
  );
}

/// Eligibility filter for manually pinned UTXOs.
///
/// Skips the confirmation check entirely — the user explicitly chose these
/// inputs, so confirmation policy is not our call. Still removes dust inputs
/// (effectiveSatoshis ≤ 0) because signing them costs more than they contribute.
final class PinnedUtxoEligibilityFilter implements UtxoEligibilityFilter {
  const PinnedUtxoEligibilityFilter();

  @override
  List<CoinCandidate> filter(
    List<CoinCandidate> candidates,
    EligibilityPolicy policy,
    FeeEstimator feeEstimator,
    int feeRateSatPerVbyte,
  ) =>
      candidates.where((c) {
        final inputW = feeEstimator.inputVbytes(c.scriptType);

        return c.effectiveSatoshis(feeRateSatPerVbyte, inputW) > 0;
      }).toList();
}

/// Default eligibility filter implementation.
final class DefaultUtxoEligibilityFilter implements UtxoEligibilityFilter {
  const DefaultUtxoEligibilityFilter();

  @override
  List<CoinCandidate> filter(
    List<CoinCandidate> candidates,
    EligibilityPolicy policy,
    FeeEstimator feeEstimator,
    int feeRateSatPerVbyte,
  ) =>
      candidates
          .where((c) => _isEligible(c, policy, feeEstimator, feeRateSatPerVbyte))
          .toList();

  bool _isEligible(
    CoinCandidate c,
    EligibilityPolicy policy,
    FeeEstimator feeEstimator,
    int feeRateSatPerVbyte,
  ) {
    // Confirmation check.
    final confs = c.confirmations;
    if (confs == null) {
      if (!policy.allowUnknownConfirmations) return false;
    } else if (confs < policy.minConfirmations) {
      return false;
    }

    // Effective-value check — G5: remove candidates whose input fee ≥ value.
    if (!policy.allowDust) {
      final inputW = feeEstimator.inputVbytes(c.scriptType);
      if (c.effectiveSatoshis(feeRateSatPerVbyte, inputW) <= 0) return false;
    }

    return true;
  }
}
