import 'package:transaction/transaction.dart';

final class FakeUtxoScanGateway implements UtxoScanGateway {
  final List<ScannedUtxo> utxos;

  FakeUtxoScanGateway(this.utxos);

  @override
  Future<List<ScannedUtxo>> scanForAddresses(List<String> addresses) async => utxos;
}
