import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

final class FakeCoinSelector implements CoinSelector {
  Object? throwOnSelect;

  final String _name;

  @override
  String get name => _name;

  @override
  bool get isStochastic => false;

  FakeCoinSelector({String name = 'fake'}) : _name = name;

  @override
  CoinSelectionResult select(CoinSelectionRequest request) {
    final t = throwOnSelect;
    if (t != null) throw t;

    return CoinSelectionResult(
      inputs: request.candidates,
      totalInputSat: request.candidates.fold(
        Satoshi.zero,
        (sum, c) => Satoshi(sum.value + c.amountSat.value),
      ),
      feeSat: const Satoshi(1000),
      changeSat: Satoshi.zero,
    );
  }
}
