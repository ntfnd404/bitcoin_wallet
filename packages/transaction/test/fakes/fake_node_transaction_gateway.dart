import 'package:transaction/transaction.dart';

final class FakeNodeTransactionGateway implements NodeTransactionGateway {
  String newAddressResult = 'bcrt1qchange';
  Object? newAddressThrows;

  String createRawTxResult = 'raw_hex_unsigned';
  Object? createRawTxThrows;

  String signRawTxResult = 'raw_hex_signed';
  Object? signRawTxThrows;

  String? capturedSignWalletName;

  @override
  Future<String> getNewAddress(String walletName) async {
    final t = newAddressThrows;
    if (t != null) throw t;

    return newAddressResult;
  }

  @override
  Future<String> createRawTransaction({
    required List<({String txid, int vout})> inputs,
    required List<TxOutput> outputs,
  }) async {
    final t = createRawTxThrows;
    if (t != null) throw t;

    return createRawTxResult;
  }

  @override
  Future<String> signRawTransactionWithWallet(
    String walletName,
    String hexTx,
  ) async {
    capturedSignWalletName = walletName;
    final t = signRawTxThrows;
    if (t != null) throw t;

    return signRawTxResult;
  }
}
