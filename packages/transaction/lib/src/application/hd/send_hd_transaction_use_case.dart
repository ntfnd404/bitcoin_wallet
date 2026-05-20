import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/hd/hd_send_preparation.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/broadcast_gateway.dart';
import 'package:transaction/src/domain/service/transaction_signer.dart';

/// Signs and broadcasts an HD-wallet transaction.
///
/// Requires an [HdSendPreparation] produced by [PrepareHdSendUseCase].
/// The caller selects the coin-selection strategy by [strategyName].
///
/// Throws [TransactionPreparationException] if [strategyName] is not found.
/// Throws [TransactionSigningException] if signing context is missing.
/// Throws [TransactionBroadcastException] if broadcast fails.
final class SendHdTransactionUseCase {
  final TransactionSigner _signer;
  final BroadcastGateway _broadcastDataSource;

  const SendHdTransactionUseCase({
    required TransactionSigner signer,
    required BroadcastGateway broadcastDataSource,
  }) : _signer = signer,
       _broadcastDataSource = broadcastDataSource;

  /// Returns the txid of the broadcast transaction.
  Future<String> call({
    required HdSendPreparation preparation,
    required String strategyName,
    required String walletId,
    required String recipientAddress,
    required Satoshi amountSat,
    required String bech32Hrp,
  }) async {
    final entries = preparation.strategies.where((e) => e.name == strategyName);
    if (entries.isEmpty) throw const TransactionPreparationException();
    final result = entries.first.result;

    final String hexSigned;
    try {
      final signingInputs = result.inputs.map((c) {
        final input = preparation.signingInputs[(c.txid, c.vout)];
        if (input == null) {
          throw const TransactionSigningException();
        }

        return input;
      }).toList();

      hexSigned = await _signer.sign(
        walletId: walletId,
        inputs: signingInputs,
        recipientAddress: recipientAddress,
        amountSat: amountSat,
        changeAddress: preparation.changeAddress,
        changeSat: result.changeSat,
        bech32Hrp: bech32Hrp,
      );
    } on TransactionSigningException {
      rethrow;
    } on TransactionPreparationException {
      rethrow;
    } on Exception catch (_, stack) {
      // 4-criteria (C1: translate keys-BC exception to transaction-BC language,
      // C2: hide potential key material from signer, C3: preserve stack,
      // C4: caller distinguishes signing vs broadcast failures).
      // TODO(ntfnd404): narrow to on KeysException subtypes once keys dep is added to pubspec.yaml.
      Error.throwWithStackTrace(const TransactionSigningException(), stack);
    }
    // Programmer errors from signing propagate to the zone handler.

    try {
      return await _broadcastDataSource.broadcast(hexSigned);
    } on TransactionException {
      rethrow;
    } on Exception catch (_, stack) {
      // 4-criteria (C1: translate RpcException to BC language, C2: n/a, C3: preserve stack, C4: typed recovery for caller).
      Error.throwWithStackTrace(const TransactionBroadcastException(), stack);
    }
    // Programmer errors from broadcast propagate to the zone handler.
  }
}
