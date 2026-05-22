import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

final class FakeFeeEstimator implements FeeEstimator {
  /// Returned by [estimateForCandidates]. Defaults to 200 sat.
  Satoshi estimateResult = const Satoshi(200);

  @override
  Satoshi estimateForCandidates({
    required List<CoinCandidate> inputs,
    required int outputs,
    required int feeRateSatPerVbyte,
  }) => estimateResult;

  @override
  int inputVbytes(AddressType scriptType) => 68;

  @override
  int dustThreshold(AddressType scriptType) => 294;
}
