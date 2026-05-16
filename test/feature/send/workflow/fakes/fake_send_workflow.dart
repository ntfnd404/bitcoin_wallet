import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

final class FakeSendWorkflow implements SendWorkflow {
  SendPreparation? prepareResult;
  Exception? prepareThrows;

  String? confirmResult;
  Exception? confirmThrows;

  SendPreparation? capturedConfirmPreparation;
  String? capturedConfirmStrategyName;
  String? capturedConfirmRecipientAddress;
  Satoshi? capturedConfirmAmountSat;

  @override
  Future<SendPreparation> prepare({
    required Satoshi targetSat,
    required int feeRateSatPerVbyte,
  }) async {
    final t = prepareThrows;
    if (t != null) throw t;

    final result = prepareResult;
    if (result == null) throw StateError('FakeSendWorkflow.prepareResult not set');

    return result;
  }

  @override
  Future<String> confirm({
    required SendPreparation preparation,
    required String strategyName,
    required String recipientAddress,
    required Satoshi amountSat,
  }) async {
    capturedConfirmPreparation = preparation;
    capturedConfirmStrategyName = strategyName;
    capturedConfirmRecipientAddress = recipientAddress;
    capturedConfirmAmountSat = amountSat;

    final t = confirmThrows;
    if (t != null) throw t;

    final result = confirmResult;
    if (result == null) throw StateError('FakeSendWorkflow.confirmResult not set');

    return result;
  }
}
