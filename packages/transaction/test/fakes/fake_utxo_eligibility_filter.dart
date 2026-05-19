import 'package:transaction/transaction.dart';

final class FakeUtxoEligibilityFilter implements UtxoEligibilityFilter {
  List<CoinCandidate> result = const [];
  List<CoinCandidate>? capturedCandidates;
  EligibilityPolicy? capturedPolicy;

  @override
  List<CoinCandidate> filter(
    List<CoinCandidate> candidates,
    EligibilityPolicy policy,
    FeeEstimator feeEstimator,
    int feeRateSatPerVbyte,
  ) {
    capturedCandidates = candidates;
    capturedPolicy = policy;

    return result;
  }
}
