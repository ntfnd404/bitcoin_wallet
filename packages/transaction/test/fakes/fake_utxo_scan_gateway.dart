import 'package:transaction/transaction.dart';

final class FakeUtxoScanGateway implements UtxoScanGateway {
  List<ScannedUtxo> scanResult = const [];
  Object? throwOnScan;

  @override
  Future<List<ScannedUtxo>> scanForAddresses(List<String> addresses) async {
    final t = throwOnScan;
    if (t != null) throw t;

    return scanResult;
  }
}
