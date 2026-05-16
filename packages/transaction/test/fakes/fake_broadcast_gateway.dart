import 'package:transaction/transaction.dart';

final class FakeBroadcastGateway implements BroadcastGateway {
  String broadcastResult = 'txid_abc123';
  Object? broadcastThrows;
  Object? getTransactionThrows;

  @override
  Future<String> broadcast(String rawHex) async {
    final t = broadcastThrows;
    if (t != null) throw t;

    return broadcastResult;
  }

  @override
  Future<BroadcastedTx> getTransaction(String txid) async {
    final t = getTransactionThrows;
    if (t != null) throw t;

    return BroadcastedTx(txid: txid, confirmations: 1, hex: 'deadbeef');
  }
}
