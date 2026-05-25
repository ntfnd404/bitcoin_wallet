/// Typed exceptions for the transaction bounded context.
///
/// Throw via [Error.throwWithStackTrace] when wrapping infra errors so the
/// original stack trace is preserved.
///
/// Note: [InsufficientFundsException] is handled internally by the coin
/// selector and never propagates to use case callers — it is not part of
/// this sealed hierarchy.
sealed class TransactionException implements Exception {
  const TransactionException();
}

/// Transaction broadcast to the network failed.
final class TransactionBroadcastException extends TransactionException {
  const TransactionBroadcastException();

  @override
  String toString() => 'Transaction broadcast failed';
}

/// Send preparation failed (infra or UTXO fetch error).
final class TransactionPreparationException extends TransactionException {
  const TransactionPreparationException();

  @override
  String toString() => 'Transaction preparation failed';
}

/// Transaction signing failed.
final class TransactionSigningException extends TransactionException {
  const TransactionSigningException();

  @override
  String toString() => 'Transaction signing failed';
}

/// Fetching transaction data from the node failed.
final class TransactionFetchException extends TransactionException {
  const TransactionFetchException();

  @override
  String toString() => 'Failed to fetch transaction data';
}

/// UTXO scan failed.
final class TransactionUtxoScanException extends TransactionException {
  const TransactionUtxoScanException();

  @override
  String toString() => 'UTXO scan failed';
}

/// A pinned input references an address not known to the HD wallet, so no
/// private key can be derived for it. Carries the offending input's identity
/// so the UI can surface a precise error.
///
/// Lives in the same library as [TransactionException] because Dart 3
/// forbids extending a `sealed` type across libraries.
final class UnknownPinnedInputAddressException extends TransactionException {
  final String txid;
  final int vout;
  final String address;

  const UnknownPinnedInputAddressException({
    required this.txid,
    required this.vout,
    required this.address,
  });

  @override
  String toString() => 'UnknownPinnedInputAddressException(txid: $txid, vout: $vout, address: $address)';
}

/// A chosen [CoinCandidate] has no matching entry in
/// [HdSigningContext.inputs] — the signer cannot produce a signature for it.
///
/// Carries only `(txid, vout)` to identify the offending input. The
/// candidate's address and BIP-32 derivation index are deliberately **not**
/// included (PRD BW-0018 Phase 2 security requirements #2, #3, #4).
///
/// Lives in the same library as [TransactionException] because Dart 3
/// forbids extending a `sealed` type across libraries.
final class MissingSigningInputException extends TransactionException {
  final String txid;
  final int vout;

  const MissingSigningInputException({required this.txid, required this.vout});

  @override
  String toString() => 'MissingSigningInputException(txid: $txid, vout: $vout)';
}
