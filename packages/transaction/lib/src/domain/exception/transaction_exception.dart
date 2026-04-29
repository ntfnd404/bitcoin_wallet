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
