/// Typed exceptions for the keys bounded context.
///
/// Security: no subclass carries seed bytes, private key bytes, mnemonic
/// words, or wallet identifiers. Do NOT add fields that could expose key
/// material through logs or error messages.
///
/// Throw via [Error.throwWithStackTrace] when wrapping crypto errors so the
/// original stack trace is preserved without leaking the error message.
sealed class KeysException implements Exception {
  const KeysException();
}

/// No seed was found for the given wallet.
final class KeysSeedNotFoundException extends KeysException {
  const KeysSeedNotFoundException();

  @override
  String toString() => 'Wallet seed not found';
}

/// Key derivation failed (e.g. degenerate elliptic-curve point).
final class KeysDerivationException extends KeysException {
  const KeysDerivationException();

  @override
  String toString() => 'Key derivation failed';
}

/// Transaction signing failed.
final class KeysSigningException extends KeysException {
  const KeysSigningException();

  @override
  String toString() => 'Transaction signing failed';
}

/// A storage operation for keys/seed material failed.
///
/// Security: zero-arg, fixed message. Carries no walletId, no key material,
/// no platform-error details. Use [Error.throwWithStackTrace] to preserve
/// the original stack trace.
final class KeysStorageException extends KeysException {
  const KeysStorageException();

  @override
  String toString() => 'Keys storage error';
}
