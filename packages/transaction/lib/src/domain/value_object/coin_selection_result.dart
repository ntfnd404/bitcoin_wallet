import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';

/// The output of a single [CoinSelector] strategy run.
///
/// [changeSat] is [Satoshi.zero] when the computed change fell below the dust
/// threshold (546 sat) — in that case the dust is absorbed into the fee.
final class CoinSelectionResult {
  final List<CoinCandidate> inputs;
  final Satoshi totalInputSat;
  final Satoshi feeSat;
  final Satoshi changeSat;

  const CoinSelectionResult({
    required this.inputs,
    required this.totalInputSat,
    required this.feeSat,
    required this.changeSat,
  });
}
