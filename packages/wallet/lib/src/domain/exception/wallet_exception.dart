/// Typed exceptions for the wallet bounded context.
///
/// All subtypes implement [Exception] so callers can catch the sealed
/// hierarchy exhaustively with `on WalletException catch`.
///
/// Throw via [Error.throwWithStackTrace] when wrapping infra errors so the
/// original stack trace is preserved.
sealed class WalletException implements Exception {
  const WalletException();
}

/// No wallet was found for the given identifier.
final class WalletNotFoundException extends WalletException {
  const WalletNotFoundException();

  @override
  String toString() => 'Wallet not found';
}

/// A wallet with the same name already exists.
final class WalletAlreadyExistsException extends WalletException {
  const WalletAlreadyExistsException();

  @override
  String toString() => 'Wallet already exists';
}

/// The provided BIP39 mnemonic failed checksum validation.
final class WalletInvalidMnemonicException extends WalletException {
  const WalletInvalidMnemonicException();

  @override
  String toString() => 'Invalid BIP39 mnemonic';
}

/// A storage or persistence operation failed.
final class WalletStorageException extends WalletException {
  const WalletStorageException();

  @override
  String toString() => 'Wallet storage error';
}
