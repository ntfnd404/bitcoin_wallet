import 'package:transaction/transaction.dart';

final class FakeBroadcastGateway implements BroadcastGateway {
  String broadcastReturn = 'fake-txid';
  Object? broadcastError;

  BroadcastedTx? getTransactionReturn;
  Object? getTransactionError;

  @override
  Future<String> broadcast(String rawHex) async {
    final e = broadcastError;
    if (e != null) throw e;

    return broadcastReturn;
  }

  @override
  Future<BroadcastedTx> getTransaction(String txid) async {
    final e = getTransactionError;
    if (e != null) throw e;

    return getTransactionReturn ??
        BroadcastedTx(txid: txid, confirmations: 0, hex: 'deadbeef');
  }
}
