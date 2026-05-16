import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

final class FakePrepareNodeSendUseCase {
  NodeSendPreparation? returnValue;
  Exception? throwsValue;

  String? capturedWalletName;
  Satoshi? capturedTargetSat;
  int? capturedFeeRate;

  Future<NodeSendPreparation> call({
    required String walletName,
    required Satoshi targetSat,
    required int feeRateSatPerVbyte,
  }) async {
    capturedWalletName = walletName;
    capturedTargetSat = targetSat;
    capturedFeeRate = feeRateSatPerVbyte;

    final t = throwsValue;
    if (t != null) throw t;

    final v = returnValue;
    if (v == null) throw StateError('FakePrepareNodeSendUseCase.returnValue not set');

    return v;
  }
}
