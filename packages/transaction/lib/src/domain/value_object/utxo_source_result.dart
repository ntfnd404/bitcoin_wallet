import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/signing_context.dart';

/// Atomic result of a [UtxoSource.resolve] call.
///
/// All three fields are produced together because for HD wallets the
/// `changeAddress` (highest-index native-segwit address) is derived from the
/// same address-set traversal that builds the signing context.
final class UtxoSourceResult {
  final List<CoinCandidate> candidates;
  final String changeAddress;
  final SigningContext signingContext;

  const UtxoSourceResult({
    required this.candidates,
    required this.changeAddress,
    required this.signingContext,
  });
}
