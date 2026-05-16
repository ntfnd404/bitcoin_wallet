import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

final class FakeSendHdTransactionUseCase {
  String? returnValue;
  Exception? throwsValue;

  HdSendPreparation? capturedPreparation;
  String? capturedStrategyName;
  String? capturedWalletId;
  String? capturedRecipientAddress;
  Satoshi? capturedAmountSat;
  String? capturedBech32Hrp;

  Future<String> call({
    required HdSendPreparation preparation,
    required String strategyName,
    required String walletId,
    required String recipientAddress,
    required Satoshi amountSat,
    required String bech32Hrp,
  }) async {
    capturedPreparation = preparation;
    capturedStrategyName = strategyName;
    capturedWalletId = walletId;
    capturedRecipientAddress = recipientAddress;
    capturedAmountSat = amountSat;
    capturedBech32Hrp = bech32Hrp;

    final t = throwsValue;
    if (t != null) throw t;

    final v = returnValue;
    if (v == null) throw StateError('FakeSendHdTransactionUseCase.returnValue not set');

    return v;
  }
}
