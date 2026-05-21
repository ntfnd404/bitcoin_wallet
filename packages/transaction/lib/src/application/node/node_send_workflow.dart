import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/node/prepare_node_send_use_case.dart';
import 'package:transaction/src/application/node/send_node_transaction_use_case.dart';
import 'package:transaction/src/application/send_preparation.dart';
import 'package:transaction/src/application/send_workflow.dart';

final class NodeSendWorkflow implements SendWorkflow {
  final PrepareNodeSendUseCase _prepare;
  final SendNodeTransactionUseCase _send;
  final String _walletName;

  const NodeSendWorkflow({
    required this._prepare,
    required this._send,
    required this._walletName,
  });

  @override
  Future<SendPreparation> prepare({
    required Satoshi targetSat,
    required int feeRateSatPerVbyte,
  }) async {
    final prep = await _prepare(
      walletName: _walletName,
      targetSat: targetSat,
      feeRateSatPerVbyte: feeRateSatPerVbyte,
    );

    return NodeSendResult(
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
    if (preparation is! NodeSendResult) {
      throw ArgumentError('NodeSendWorkflow.confirm received wrong preparation type');
    }

    return _send(
      preparation: preparation.inner,
      strategyName: strategyName,
      walletName: _walletName,
      recipientAddress: recipientAddress,
      amountSat: amountSat,
    );
  }
}
