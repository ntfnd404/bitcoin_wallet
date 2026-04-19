import 'package:shared_kernel/shared_kernel.dart';

/// Estimates the transaction fee given input/output counts and a fee rate.
abstract interface class FeeEstimator {
  Satoshi estimate({
    required int inputs,
    required int outputs,
    required int feeRateSatPerVbyte,
  });
}

/// P2WPKH virtual-byte fee estimator.
///
/// Formula: `vbytes = 10 + inputs × 68 + outputs × 31`
///
/// - 10 vbytes: version (4) + locktime (4) + segwit marker/flag (2) overhead
/// - 68 vbytes per input: outpoint (41) + sequence (4) + witness (1 + 1 + 73 + 33)
/// - 31 vbytes per output: value (8) + scriptPubKey length (1) + P2WPKH script (22)
final class P2wpkhFeeEstimator implements FeeEstimator {
  const P2wpkhFeeEstimator();

  @override
  Satoshi estimate({
    required int inputs,
    required int outputs,
    required int feeRateSatPerVbyte,
  }) {
    final vbytes = 10 + inputs * 68 + outputs * 31;

    return Satoshi(vbytes * feeRateSatPerVbyte);
  }
}
