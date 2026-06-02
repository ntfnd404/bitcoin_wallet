import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/prepare_send_use_case.dart';
import 'package:transaction/src/application/send_preparation.dart';
import 'package:transaction/src/application/send_workflow.dart';
import 'package:transaction/src/domain/contract/signer.dart';
import 'package:transaction/src/domain/contract/utxo_source.dart';

/// Composes [UtxoSource], [Signer], and [PrepareSendUseCase] into a [SendWorkflow].
final class SendWorkflowImpl implements SendWorkflow {
  final UtxoSource _source;
  final Signer _signer;
  final PrepareSendUseCase _prepare;

  const SendWorkflowImpl({
    required this._source,
    required this._signer,
    required this._prepare,
  });

  @override
  Future<SendPreparation> prepare({
    required Satoshi targetSat,
    required int feeRateSatPerVbyte,
  }) => _prepare(
    source: _source,
    targetSat: targetSat,
    feeRateSatPerVbyte: feeRateSatPerVbyte,
  );

  @override
  Future<String> confirm({
    required SendPreparation preparation,
    required String strategyName,
    required String recipientAddress,
    required Satoshi amountSat,
  }) {
    final strategy = preparation.strategies.where((s) => s.name == strategyName).first;

    return _signer.signAndBroadcast(
      strategy: strategy,
      signingContext: preparation.signingContext,
      recipientAddress: recipientAddress,
      amountSat: amountSat,
      changeAddress: preparation.changeAddress,
    );
  }
}
