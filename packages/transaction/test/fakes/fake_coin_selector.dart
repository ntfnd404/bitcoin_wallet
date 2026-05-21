import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

final class FakeCoinSelector implements CoinSelector {
  Object? throwOnSelect;
  List<CoinCandidate>? capturedCandidates;

  final String _name;

  @override
  String get name => _name;

  @override
  bool get isStochastic => false;

  FakeCoinSelector({this._name = 'fake'});

  @override
  CoinSelectionResult select(CoinSelectionRequest request) {
    capturedCandidates = request.candidates;
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
