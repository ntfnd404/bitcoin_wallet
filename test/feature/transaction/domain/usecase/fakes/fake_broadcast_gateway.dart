import 'package:transaction/transaction.dart';

final class FakeBroadcastGateway implements BroadcastGateway {
  Object? broadcastThrows;
  Object? getTransactionThrows;
  String broadcastResult = 'txid_abc123';

  @override
  Future<String> broadcast(String rawHex) async {
    final toThrow = broadcastThrows;
    if (toThrow != null) throw toThrow;

    return broadcastResult;
  }

  @override
  Future<BroadcastedTx> getTransaction(String txid) async {
    final toThrow = getTransactionThrows;
    if (toThrow != null) throw toThrow;

    return BroadcastedTx(txid: txid, confirmations: 1, hex: 'deadbeef');
  }
}
