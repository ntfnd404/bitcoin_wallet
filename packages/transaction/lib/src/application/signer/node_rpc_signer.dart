import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/contract/signer.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/broadcast_gateway.dart';
import 'package:transaction/src/domain/gateway/node_transaction_gateway.dart';
import 'package:transaction/src/domain/value_object/coin_selection_strategy_result.dart';
import 'package:transaction/src/domain/value_object/signer_payload.dart';
import 'package:transaction/src/domain/value_object/tx_output.dart';

/// Node-wallet [Signer] — builds a raw transaction via
/// `createrawtransaction`, asks Bitcoin Core to sign it via
/// `signrawtransactionwithwallet`, and broadcasts the signed hex.
///
final class NodeRpcSigner implements Signer {
  final String _walletName;
  final NodeTransactionGateway _nodeTransactionGateway;
  final BroadcastGateway _broadcastGateway;

  const NodeRpcSigner({
    required this._walletName,
    required this._nodeTransactionGateway,
    required this._broadcastGateway,
  });

  @override
  Future<String> signAndBroadcast({
    required CoinSelectionStrategyResult strategy,
    required SignerPayload signingContext,
    required String recipientAddress,
    required Satoshi amountSat,
    required String changeAddress,
  }) async {
    if (signingContext is! NodeSignerPayload) {
      throw const TransactionSigningException();
    }

    final result = strategy.result;

    try {
      // 1. Build inputs list from selected strategy result.
      final inputs = result.inputs.map((c) => (txid: c.txid, vout: c.vout)).toList();

      // 2. Build outputs: recipient output + optional change output.
      final outputs = <TxOutput>[
        AddressOutput(
          address: recipientAddress,
          amountBtc: amountSat.btcAmount,
        ),
        if (result.changeSat.value > 0)
          AddressOutput(
            address: changeAddress,
            amountBtc: result.changeSat.btcAmount,
          ),
      ];

      // 3. Create unsigned raw transaction via createrawtransaction.
      final hexUnsigned = await _nodeTransactionGateway.createRawTransaction(
        inputs: inputs,
        outputs: outputs,
      );

      // 4. Sign with Bitcoin Core via signrawtransactionwithwallet.
      final hexSigned = await _nodeTransactionGateway.signRawTransactionWithWallet(
        _walletName,
        hexUnsigned,
      );

      // 5. Broadcast signed hex.
      return _broadcastGateway.broadcast(hexSigned);
    } on TransactionSigningException {
      rethrow;
    } on TransactionException {
      rethrow;
    } on Exception catch (_, stack) {
      // 4-criteria (C1: translate RpcException from broadcast/RPC gateway,
      // C2: n/a, C3: preserve stack, C4: typed recovery for caller).
      Error.throwWithStackTrace(const TransactionBroadcastException(), stack);
    }
    // Programmer errors propagate to the zone handler.
  }
}
