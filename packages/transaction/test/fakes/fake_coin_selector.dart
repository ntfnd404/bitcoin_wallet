import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

final class FakeCoinSelector implements CoinSelector {
  Object? throwOnSelect;

  final String _name;

  @override
  String get name => _name;

  FakeCoinSelector({String name = 'fake'}) : _name = name;

  @override
  CoinSelectionResult select({
    required List<CoinCandidate> candidates,
    required Satoshi targetSat,
    required FeeEstimator feeEstimator,
    required int feeRateSatPerVbyte,
    required int dustThreshold,
  }) {
    final t = throwOnSelect;
    if (t != null) throw t;

    return CoinSelectionResult(
      inputs: candidates,
      totalInputSat: candidates.fold(
        Satoshi.zero,
        (sum, c) => Satoshi(sum.value + c.amountSat.value),
      ),
      feeSat: const Satoshi(1000),
      changeSat: Satoshi.zero,
    );
  }
}
