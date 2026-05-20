import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';

/// Estimates transaction fees with per-candidate input weight awareness.
abstract interface class FeeEstimator {
  /// Per-candidate-aware estimation. Uses [CoinCandidate.scriptType] to
  /// compute the correct weight per input.
  Satoshi estimateForCandidates({
    required List<CoinCandidate> inputs,
    required int outputs,
    required int feeRateSatPerVbyte,
  });

  /// Virtual bytes for a single input of [scriptType].
  int inputVbytes(AddressType scriptType);

  /// Minimum non-dust output value for [scriptType].
  ///
  /// Outputs below this are dust — fold into fee or exclude. Bitcoin Core defaults:
  /// P2WPKH=294, P2PKH=546, P2TR=330, P2SH-P2WPKH=546
  int dustThreshold(AddressType scriptType);
}

/// P2WPKH-aware fee estimator with per-script-type input weights.
///
/// Overhead: 10 vbytes (version 4 + locktime 4 + segwit marker/flag 2)
/// Output:   31 vbytes (value 8 + scriptLen 1 + P2WPKH script 22)
///
/// Input weights by type:
/// - nativeSegwit (P2WPKH): 68 vbytes
/// - legacy (P2PKH):        148 vbytes
/// - taproot (P2TR):        58 vbytes  (key-path spend)
/// - wrappedSegwit (P2SH):  91 vbytes
final class P2wpkhFeeEstimator implements FeeEstimator {
  const P2wpkhFeeEstimator();

  @override
  int inputVbytes(AddressType scriptType) => switch (scriptType) {
    AddressType.nativeSegwit  => 68,
    AddressType.legacy        => 148,
    AddressType.taproot       => 58,
    AddressType.wrappedSegwit => 91,
  };

  @override
  int dustThreshold(AddressType scriptType) => switch (scriptType) {
    AddressType.nativeSegwit  => 294,
    AddressType.legacy        => 546,
    AddressType.taproot       => 330,
    AddressType.wrappedSegwit => 546,
  };

  @override
  Satoshi estimateForCandidates({
    required List<CoinCandidate> inputs,
    required int outputs,
    required int feeRateSatPerVbyte,
  }) {
    final inputVbyteTotal = inputs.fold(
      0,
      (sum, c) => sum + inputVbytes(c.scriptType),
    );
    final vbytes = 10 + inputVbyteTotal + outputs * 31;

    return Satoshi(vbytes * feeRateSatPerVbyte);
  }
}
