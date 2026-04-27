import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/hd/hd_send_preparation.dart';
import 'package:transaction/src/domain/data_sources/broadcast_data_source.dart';
import 'package:transaction/src/domain/service/transaction_signer.dart';

/// Signs and broadcasts an HD-wallet transaction.
///
/// Requires an [HdSendPreparation] produced by [PrepareHdSendUseCase].
/// The caller selects the coin-selection strategy by [strategyName].
final class SendHdTransactionUseCase {
  final TransactionSigner _signer;
  final BroadcastDataSource _broadcastDataSource;

  const SendHdTransactionUseCase({
    required TransactionSigner signer,
    required BroadcastDataSource broadcastDataSource,
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
    final result = preparation.strategies[strategyName];
    if (result == null) {
      throw ArgumentError('Strategy "$strategyName" not found in preparation');
    }

    final signingInputs = result.inputs.map((c) {
      final input = preparation.signingInputs[(c.txid, c.vout)];
      if (input == null) {
        throw StateError(
          'No signing context for ${c.txid}:${c.vout}. '
          'Was PrepareHdSendUseCase run with the same UTXO set?',
        );
      }

      return input;
    }).toList();

    final hexSigned = await _signer.sign(
      walletId: walletId,
      inputs: signingInputs,
      recipientAddress: recipientAddress,
      amountSat: amountSat,
      changeAddress: preparation.changeAddress,
      changeSat: result.changeSat,
      bech32Hrp: bech32Hrp,
    );

    return _broadcastDataSource.broadcast(hexSigned);
  }
}
