import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/node/prepare_node_pinned_send_use_case.dart';
import 'package:transaction/src/application/node/send_node_transaction_use_case.dart';
import 'package:transaction/src/application/send_preparation.dart';
import 'package:transaction/src/application/send_workflow.dart';
import 'package:transaction/src/domain/entity/utxo.dart';

/// [SendWorkflow] variant that uses pinned UTXOs as fixed inputs.
///
/// Mirrors [NodeSendWorkflow] but passes [pinnedInputs] to
/// [PrepareNodePinnedSendUseCase] instead of fetching from the repository.
/// Returns [NodeSendResult] — same sealed type — so [SendBloc] requires no changes.
final class NodePinnedSendWorkflow implements SendWorkflow {
  final PrepareNodePinnedSendUseCase _prepare;
  final SendNodeTransactionUseCase _send;
  final String _walletName;
  final List<Utxo> _pinnedInputs;

  const NodePinnedSendWorkflow({
    required this._prepare,
    required this._send,
    required this._walletName,
    required this._pinnedInputs,
  });

  @override
  Future<SendPreparation> prepare({
    required Satoshi targetSat,
    required int feeRateSatPerVbyte,
  }) async {
    final prep = await _prepare(
      walletName: _walletName,
      pinnedInputs: _pinnedInputs,
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
      throw ArgumentError(
        'NodePinnedSendWorkflow.confirm received wrong preparation type',
      );
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
