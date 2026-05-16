import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

final class FakePrepareHdSendUseCase {
  HdSendPreparation? returnValue;
  Exception? throwsValue;

  String? capturedWalletId;
  Satoshi? capturedTargetSat;
  int? capturedFeeRate;

  Future<HdSendPreparation> call({
    required String walletId,
    required Satoshi targetSat,
    required int feeRateSatPerVbyte,
  }) async {
    capturedWalletId = walletId;
    capturedTargetSat = targetSat;
    capturedFeeRate = feeRateSatPerVbyte;

    final t = throwsValue;
    if (t != null) throw t;

    final v = returnValue;
    if (v == null) throw StateError('FakePrepareHdSendUseCase.returnValue not set');

    return v;
  }
}
