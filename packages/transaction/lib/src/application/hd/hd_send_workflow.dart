import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/hd/prepare_hd_send_use_case.dart';
import 'package:transaction/src/application/hd/send_hd_transaction_use_case.dart';
import 'package:transaction/src/application/send_preparation.dart';
import 'package:transaction/src/application/send_workflow.dart';

final class HdSendWorkflow implements SendWorkflow {
  final PrepareHdSendUseCase _prepare;
  final SendHdTransactionUseCase _send;
  final String _walletId;
  final String _bech32Hrp;

  const HdSendWorkflow({
    required this._prepare,
    required this._send,
    required this._walletId,
    required this._bech32Hrp,
  });

  @override
  Future<SendPreparation> prepare({
    required Satoshi targetSat,
    required int feeRateSatPerVbyte,
  }) async {
    final prep = await _prepare(
      walletId: _walletId,
      targetSat: targetSat,
      feeRateSatPerVbyte: feeRateSatPerVbyte,
    );

    return HdSendResult(
      strategies: prep.strategies,
      changeAddress: prep.changeAddress,
      inner: prep,
    );
  }

  @override
  Future<String> confirm({
    required SendPreparation preparation,
    required String strategyName,
    required String recipientAddress,
    required Satoshi amountSat,
  }) async {
    if (preparation is! HdSendResult) {
      throw ArgumentError('HdSendWorkflow.confirm received wrong preparation type');
    }

    return _send(
      preparation: preparation.inner,
      strategyName: strategyName,
      walletId: _walletId,
      recipientAddress: recipientAddress,
      amountSat: amountSat,
      bech32Hrp: _bech32Hrp,
    );
  }
}
