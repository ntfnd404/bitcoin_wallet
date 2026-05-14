import 'package:transaction/transaction.dart';

final class FakeUtxoScanGateway implements UtxoScanGateway {
  Object? throwOnScan;
  List<ScannedUtxo> scanResult = const [];

  @override
  Future<List<ScannedUtxo>> scanForAddresses(List<String> addresses) async {
    final toThrow = throwOnScan;
    if (toThrow != null) throw toThrow;

    return scanResult;
  }
}
