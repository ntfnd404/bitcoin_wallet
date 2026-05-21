import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/node/node_send_preparation.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/broadcast_gateway.dart';
import 'package:transaction/src/domain/gateway/node_transaction_gateway.dart';
import 'package:transaction/src/domain/value_object/tx_output.dart';

/// Builds, signs (via Bitcoin Core), and broadcasts a Node-wallet transaction.
///
/// Requires a [NodeSendPreparation] produced by [PrepareNodeSendUseCase].
/// The caller selects the coin-selection strategy by [strategyName].
///
/// Throws [TransactionPreparationException] if [strategyName] is not found.
/// Throws [TransactionBroadcastException] if the RPC or broadcast call fails.
final class SendNodeTransactionUseCase {
  final NodeTransactionGateway _nodeDataSource;
  final BroadcastGateway _broadcastDataSource;

  const SendNodeTransactionUseCase({
    required this._nodeDataSource,
    required this._broadcastDataSource,
  });

  /// Returns the txid of the broadcast transaction.
  Future<String> call({
    required NodeSendPreparation preparation,
    required String strategyName,
    required String walletName,
    required String recipientAddress,
    required Satoshi amountSat,
  }) async {
    final entries = preparation.strategies.where((e) => e.name == strategyName);
    if (entries.isEmpty) throw const TransactionPreparationException();
    final result = entries.first.result;

    try {
      final inputs = result.inputs.map((c) => (txid: c.txid, vout: c.vout)).toList();

      final outputs = <TxOutput>[
        AddressOutput(
          address: recipientAddress,
          amountBtc: amountSat.btcAmount,
        ),
        if (result.changeSat.value > 0)
          AddressOutput(
            address: preparation.changeAddress,
            amountBtc: result.changeSat.btcAmount,
          ),
      ];

      final hexUnsigned = await _nodeDataSource.createRawTransaction(
        inputs: inputs,
        outputs: outputs,
      );

      final hexSigned = await _nodeDataSource.signRawTransactionWithWallet(
        walletName,
        hexUnsigned,
      );

      return _broadcastDataSource.broadcast(hexSigned);
    } on TransactionSigningException {
      rethrow;
    } on TransactionException {
      rethrow;
    } on Exception catch (_, stack) {
      // 4-criteria (C1: translate RpcException from broadcast gateway, C2: n/a, C3: preserve stack, C4: typed recovery for caller).
      Error.throwWithStackTrace(const TransactionBroadcastException(), stack);
    }
    // Programmer errors propagate to the zone handler.
  }
}
