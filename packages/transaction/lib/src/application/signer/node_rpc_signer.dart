import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/contract/signer.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/broadcast_gateway.dart';
import 'package:transaction/src/domain/gateway/node_transaction_gateway.dart';
import 'package:transaction/src/domain/value_object/coin_selection_strategy_result.dart';
import 'package:transaction/src/domain/value_object/signing_context.dart';
import 'package:transaction/src/domain/value_object/tx_output.dart';

/// Node-wallet [Signer] — builds a raw transaction via
/// `createrawtransaction`, asks Bitcoin Core to sign it via
/// `signrawtransactionwithwallet`, and broadcasts the signed hex.
///
/// Mirrors the legacy `SendNodeTransactionUseCase` body verbatim
/// (BW-0018 Phase 2 — structural extraction only).
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
    required SigningContext signingContext,
    required String recipientAddress,
    required Satoshi amountSat,
    required String changeAddress,
  }) async {
    if (signingContext is! NodeSigningContext) {
      throw const TransactionSigningException();
    }

    final result = strategy.result;

    try {
      final inputs = result.inputs.map((c) => (txid: c.txid, vout: c.vout)).toList();

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

      final hexUnsigned = await _nodeTransactionGateway.createRawTransaction(
        inputs: inputs,
        outputs: outputs,
      );

      final hexSigned = await _nodeTransactionGateway.signRawTransactionWithWallet(
        _walletName,
        hexUnsigned,
      );

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
