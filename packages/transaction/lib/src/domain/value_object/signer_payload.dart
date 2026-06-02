import 'package:transaction/src/domain/value_object/signing_input.dart';

/// Sealed signing context returned by every [UtxoSource].
///
/// Each wallet flavour produces the data its [Signer] needs:
/// - [NodeSignerPayload] — empty marker (Node Wallet signs server-side and
///   needs no per-input data).
/// - [HdSignerPayload] — carries `Map<(String txid, int vout), SigningInput>`
///   so the offline HD signer has all material required for BIP-143 sighashes.
sealed class SignerPayload {
  const SignerPayload();
}

/// Marker context for Node-wallet sends — keys live in Bitcoin Core, no
/// per-input data is needed at sign time.
final class NodeSignerPayload extends SignerPayload {
  const NodeSignerPayload();
}

/// Signing context for HD-wallet sends.
///
/// [inputs] is keyed by `(txid, vout)` of every candidate that resolves to a
/// known HD address. Wrapped in [Map.unmodifiable] at construction time.
final class HdSignerPayload extends SignerPayload {
  final Map<(String, int), SigningInput> inputs;

  HdSignerPayload(Map<(String, int), SigningInput> inputs) : inputs = Map.unmodifiable(inputs);
}
