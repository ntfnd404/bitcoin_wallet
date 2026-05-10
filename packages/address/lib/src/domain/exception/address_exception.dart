/// Typed exceptions for the address bounded context.
///
/// Throw via [Error.throwWithStackTrace] when wrapping infra errors so the
/// original stack trace is preserved.
sealed class AddressException implements Exception {
  const AddressException();
}

/// No address generation strategy is registered for the wallet type.
final class AddressNoStrategyException extends AddressException {
  const AddressNoStrategyException();

  @override
  String toString() => 'No address generation strategy for this wallet type';
}

/// Address generation failed (infra or derivation error).
final class AddressGenerationException extends AddressException {
  const AddressGenerationException();

  @override
  String toString() => 'Address generation failed';
}

/// A storage or persistence operation failed.
final class AddressStorageException extends AddressException {
  const AddressStorageException();

  @override
  String toString() => 'Address storage error';
}
