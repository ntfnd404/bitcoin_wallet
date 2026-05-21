import 'package:transaction/transaction.dart';

final class FakeNodeTransactionGateway implements NodeTransactionGateway {
  @override
  Future<String> getNewAddress(String walletName) async => 'bcrt1qchange';

  @override
  Future<String> createRawTransaction({
    required List<({String txid, int vout})> inputs,
    required List<TxOutput> outputs,
  }) async => 'raw_unsigned';

  @override
  Future<String> signRawTransactionWithWallet(String walletName, String hexTx) async =>
      'raw_signed';
}
