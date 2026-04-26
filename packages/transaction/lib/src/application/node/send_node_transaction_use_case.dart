import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/node/node_send_preparation.dart';
import 'package:transaction/src/domain/data_sources/broadcast_data_source.dart';
import 'package:transaction/src/domain/data_sources/node_transaction_data_source.dart';

/// Builds, signs (via Bitcoin Core), and broadcasts a Node-wallet transaction.
///
/// Requires a [NodeSendPreparation] produced by [PrepareNodeSendUseCase].
/// The caller selects the coin-selection strategy by [strategyName].
final class SendNodeTransactionUseCase {
  final NodeTransactionDataSource _nodeDataSource;
  final BroadcastDataSource _broadcastDataSource;

  const SendNodeTransactionUseCase({
    required NodeTransactionDataSource nodeDataSource,
    required BroadcastDataSource broadcastDataSource,
  }) : _nodeDataSource = nodeDataSource,
       _broadcastDataSource = broadcastDataSource;

  /// Returns the txid of the broadcast transaction.
  Future<String> call({
    required NodeSendPreparation preparation,
    required String strategyName,
    required String walletName,
    required String recipientAddress,
    required Satoshi amountSat,
  }) async {
    final result = preparation.strategies[strategyName];
    if (result == null) {
      throw ArgumentError('Strategy "$strategyName" not found in preparation');
    }

    final inputs = result.inputs.map((c) => (txid: c.txid, vout: c.vout)).toList();

    final outputs = <String, double>{
      recipientAddress: amountSat.value / 100000000,
    };

    if (result.changeSat.value > 0) {
      outputs[preparation.changeAddress] = result.changeSat.value / 100000000;
    }

    final hexUnsigned = await _nodeDataSource.createRawTransaction(
      inputs: inputs,
      outputs: outputs,
    );

    final hexSigned = await _nodeDataSource.signRawTransactionWithWallet(
      walletName,
      hexUnsigned,
    );

    return _broadcastDataSource.broadcast(hexSigned);
  }
}
