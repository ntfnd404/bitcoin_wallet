import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';
import 'package:transaction/src/domain/value_object/signing_input.dart';

/// Immutable result of [PrepareHdSendUseCase].
///
/// In addition to the strategy comparison data, carries a type-safe lookup of
/// signing context for every candidate UTXO so that [SendHdTransactionUseCase]
/// can resolve [SigningInput]s for the selected coins without re-scanning.
final class HdSendPreparation {
  final List<CoinCandidate> candidates;

  /// Strategy name → selection result for all four [CoinSelector] strategies.
  final Map<String, CoinSelectionResult> strategies;

  /// `(txid, vout)` → [SigningInput] for all scanned UTXOs in [candidates].
  final Map<(String, int), SigningInput> signingInputs;

  /// Pre-derived change address (highest-index nativeSegwit address of the wallet).
  final String changeAddress;

  const HdSendPreparation({
    required this.candidates,
    required this.strategies,
    required this.signingInputs,
    required this.changeAddress,
  });
}
