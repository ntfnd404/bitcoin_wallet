import 'package:transaction/transaction.dart';

final class FakeBroadcastGateway implements BroadcastGateway {
  String result = 'txid_ok';
  Exception? throwsValue;

  @override
  Future<String> broadcast(String rawHex) async {
    final t = throwsValue;
    if (t != null) throw t;

    return result;
  }

  @override
  Future<BroadcastedTx> getTransaction(String txid) async =>
      BroadcastedTx(txid: txid, confirmations: 1, hex: '');
}
