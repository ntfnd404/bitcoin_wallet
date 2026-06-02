import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

final class FakeSigner implements Signer {
  String signResult = 'txid_fake';
  Object? throwOnSign;
  CoinSelectionStrategyResult? capturedStrategy;
  SignerPayload? capturedSignerPayload;

  @override
  Future<String> signAndBroadcast({
    required CoinSelectionStrategyResult strategy,
    required SignerPayload signingContext,
    required String recipientAddress,
    required Satoshi amountSat,
    required String changeAddress,
  }) async {
    capturedStrategy = strategy;
    capturedSignerPayload = signingContext;
    final t = throwOnSign;
    if (t != null) throw t;

    return signResult;
  }
}
