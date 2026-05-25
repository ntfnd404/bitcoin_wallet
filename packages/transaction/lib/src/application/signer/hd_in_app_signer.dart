import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/contract/signer.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/broadcast_gateway.dart';
import 'package:transaction/src/domain/service/transaction_signer.dart';
import 'package:transaction/src/domain/value_object/coin_selection_strategy_result.dart';
import 'package:transaction/src/domain/value_object/signing_context.dart';
import 'package:transaction/src/domain/value_object/signing_input.dart';

/// HD-wallet [Signer] — assembles `SigningInput`s for the chosen candidate
/// subset, asks the [TransactionSigner] to produce a signed transaction
/// hex, and broadcasts it.
///
/// Mirrors the legacy `SendHdTransactionUseCase` body verbatim with two
/// security upgrades carried forward from BW-0018 Phase 1 security review:
/// - Iterates only the chosen `CoinSelectionStrategyResult.inputs` subset,
///   never the full [HdSigningContext.inputs] map (security req #1).
/// - Rejects a missing chosen-vin entry with a typed
///   [MissingSigningInputException] carrying only `(txid, vout)` — never
///   the input's address or derivation index (security req #3, #4).
final class HdInAppSigner implements Signer {
  final String _walletId;
  final String _bech32Hrp;
  final TransactionSigner _transactionSigner;
  final BroadcastGateway _broadcastGateway;

  const HdInAppSigner({
    required this._walletId,
    required this._bech32Hrp,
    required this._transactionSigner,
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
    if (signingContext is! HdSigningContext) {
      throw const TransactionSigningException();
    }
    final hd = signingContext;
    final result = strategy.result;

    final String hexSigned;
    try {
      final signingInputs = <SigningInput>[];
      for (final c in result.inputs) {
        final input = hd.inputs[(c.txid, c.vout)];
        if (input == null) {
          throw MissingSigningInputException(txid: c.txid, vout: c.vout);
        }
        signingInputs.add(input);
      }

      hexSigned = await _transactionSigner.sign(
        walletId: _walletId,
        inputs: signingInputs,
        recipientAddress: recipientAddress,
        amountSat: amountSat,
        changeAddress: changeAddress,
        changeSat: result.changeSat,
        bech32Hrp: _bech32Hrp,
      );
    } on TransactionSigningException {
      rethrow;
    } on TransactionPreparationException {
      rethrow;
    } on TransactionException {
      // MissingSigningInputException and other sealed subtypes bubble out
      // as typed TransactionException without being relabeled.
      rethrow;
    } on Exception catch (_, stack) {
      // 4-criteria (C1: translate keys-BC exception to transaction-BC language,
      // C2: hide potential key material from signer, C3: preserve stack,
      // C4: caller distinguishes signing vs broadcast failures).
      // TODO(ntfnd404): narrow to on KeysException subtypes once keys dep is
      // added to transaction package pubspec (carry-forward from legacy).
      Error.throwWithStackTrace(const TransactionSigningException(), stack);
    }
    // Programmer errors from signing propagate to the zone handler.

    try {
      return await _broadcastGateway.broadcast(hexSigned);
    } on TransactionException {
      rethrow;
    } on Exception catch (_, stack) {
      // 4-criteria (C1: translate RpcException to BC language, C2: n/a,
      // C3: preserve stack, C4: typed recovery for caller).
      Error.throwWithStackTrace(const TransactionBroadcastException(), stack);
    }
    // Programmer errors from broadcast propagate to the zone handler.
  }
}
