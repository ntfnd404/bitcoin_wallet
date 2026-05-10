/// Generic typed exception for [SecureStorage] failures.
///
/// SECURITY: zero-arg, fixed message. Original platform exception details
/// (e.g. `PlatformException.message`, which may contain storage keys
/// including `seed_<walletId>`) are NOT carried. The original cause is
/// preserved only via the stack trace through [Error.throwWithStackTrace].
///
/// Each bounded context's data source MUST wrap this in its own typed
/// exception (e.g. `WalletStorageException`, `KeysStorageException`) — this
/// type should not propagate past the data layer.
final class SecureStorageException implements Exception {
  const SecureStorageException();

  @override
  String toString() => 'Secure storage operation failed';
}
