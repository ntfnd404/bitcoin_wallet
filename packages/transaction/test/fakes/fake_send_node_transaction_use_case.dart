import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

final class FakeSendNodeTransactionUseCase {
  String? returnValue;
  Exception? throwsValue;

  NodeSendPreparation? capturedPreparation;
  String? capturedStrategyName;
  String? capturedWalletName;
  String? capturedRecipientAddress;
  Satoshi? capturedAmountSat;

  Future<String> call({
    required NodeSendPreparation preparation,
    required String strategyName,
    required String walletName,
    required String recipientAddress,
    required Satoshi amountSat,
  }) async {
    capturedPreparation = preparation;
    capturedStrategyName = strategyName;
    capturedWalletName = walletName;
    capturedRecipientAddress = recipientAddress;
    capturedAmountSat = amountSat;

    final t = throwsValue;
    if (t != null) throw t;

    final v = returnValue;
    if (v == null) throw StateError('FakeSendNodeTransactionUseCase.returnValue not set');

    return v;
  }
}
