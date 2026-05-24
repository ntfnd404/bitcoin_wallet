import 'package:transaction/src/domain/contract/utxo_source.dart';
import 'package:transaction/src/domain/entity/utxo.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/node_transaction_gateway.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/signing_context.dart';
import 'package:transaction/src/domain/value_object/utxo_source_result.dart';

/// UTXO source for the Node Wallet (caller-pinned-inputs variant).
///
/// Mirrors `PrepareNodePinnedSendUseCase`'s mapping step plus the
/// `getnewaddress` call. No `spendable` filter (caller invariant) and no
/// eligibility filtering — pinned inputs are passed through as-is per the
/// BW-0016 manual-UTXO-selection invariant.
final class NodePinnedUtxoSource implements UtxoSource {
  final String _walletName;
  final List<Utxo> _pinnedInputs;
  final NodeTransactionGateway _nodeTransactionGateway;

  const NodePinnedUtxoSource({
    required String walletName,
    required List<Utxo> pinnedInputs,
    required NodeTransactionGateway nodeTransactionGateway,
  })  : _walletName = walletName,
        _pinnedInputs = pinnedInputs,
        _nodeTransactionGateway = nodeTransactionGateway;

  @override
  Future<UtxoSourceResult> resolve() async {
    try {
      final candidates = _pinnedInputs.map(_toCandidate).toList();
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

  CoinCandidate _toCandidate(Utxo u) => CoinCandidate(
    txid: u.txid,
    vout: u.vout,
    amountSat: u.amountSat,
    age: u.confirmations,
    scriptType: u.type,
    scriptPubKeyHex: u.scriptPubKey,
    confirmations: u.confirmations,
  );
}
// ignore_for_file: prefer_initializing_formals

