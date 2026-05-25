import 'package:transaction/src/domain/contract/utxo_source.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/node_transaction_gateway.dart';
import 'package:transaction/src/domain/repository/utxo_repository.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/signing_context.dart';
import 'package:transaction/src/domain/value_object/utxo_source_result.dart';

/// UTXO source for the Node Wallet (auto-selection variant).
///
/// Mirrors steps 1–5 of `PrepareNodeSendUseCase`:
/// 1. Fetch all wallet UTXOs from the repository.
/// 2. Drop non-spendable rows (the `spendable` bit is not carried by
///    [CoinCandidate], so it must be applied here).
/// 3. Map to [CoinCandidate].
/// 4. Request a fresh change address from Bitcoin Core via `getnewaddress`.
/// 5. Emit a [NodeSigningContext] marker — Node Wallet signs server-side and
///    needs no per-input material.
///
/// Eligibility filtering is **not** applied here — it is the responsibility of
/// [EligibilityFilteringUtxoSource] composed around this source at the call
/// site.
final class NodeAutoUtxoSource implements UtxoSource {
  final String _walletName;
  final UtxoRepository _utxoRepository;
  final NodeTransactionGateway _nodeTransactionGateway;

  const NodeAutoUtxoSource({
    required this._walletName,
    required this._utxoRepository,
    required this._nodeTransactionGateway,
  });

  @override
  Future<UtxoSourceResult> resolve() async {
    try {
      final utxos = await _utxoRepository.getUtxos(_walletName);

      final candidates = utxos
          .where((u) => u.spendable)
          .map(
            (u) => CoinCandidate(
              txid: u.txid,
              vout: u.vout,
              amountSat: u.amountSat,
              age: u.confirmations,
              scriptType: u.type,
              scriptPubKeyHex: u.scriptPubKey,
              confirmations: u.confirmations,
            ),
          )
          .toList();

      final changeAddress = await _nodeTransactionGateway.getNewAddress(_walletName);

      return UtxoSourceResult(
        candidates: candidates,
        changeAddress: changeAddress,
        signingContext: const NodeSigningContext(),
      );
    } on TransactionException {
      rethrow;
    } on Exception catch (_, stack) {
      Error.throwWithStackTrace(const TransactionPreparationException(), stack);
    }
  }
}
