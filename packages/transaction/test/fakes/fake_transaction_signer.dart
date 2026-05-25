import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

final class FakeTransactionSigner implements TransactionSigner {
  String signResult = 'signed_hex_deadbeef';
  Object? signThrows;

  String? capturedWalletId;
  String? capturedBech32Hrp;
  List<SigningInput>? capturedInputs;

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
    capturedWalletId = walletId;
    capturedBech32Hrp = bech32Hrp;
    capturedInputs = List.unmodifiable(inputs);

    final t = signThrows;
    if (t != null) throw t;

    return signResult;
  }
}
