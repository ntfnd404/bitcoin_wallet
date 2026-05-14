import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

final class FakeTransactionSigner implements TransactionSigner {
  Object? signThrows;
  String signResult = 'signed_hex_deadbeef';

  @override
  Future<String> sign({
    required String walletId,
    required List<SigningInput> inputs,
    required String recipientAddress,
    required Satoshi amountSat,
    required String changeAddress,
    required Satoshi changeSat,
    required String bech32Hrp,
  }) async {
    final toThrow = signThrows;
    if (toThrow != null) throw toThrow;

    return signResult;
  }
}
