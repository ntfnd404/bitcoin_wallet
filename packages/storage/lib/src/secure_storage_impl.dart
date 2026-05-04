import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// [SecureStorage] backed by [FlutterSecureStorage].
///
/// Wraps platform-level exceptions in [SecureStorageException] to prevent
/// secret-leak surfaces — `PlatformException.message` may contain storage
/// keys (e.g. `seed_<walletId>`) in plain text.
final class SecureStorageImpl implements SecureStorage {
  final FlutterSecureStorage _storage;

  const SecureStorageImpl() : _storage = const FlutterSecureStorage();

  @visibleForTesting
  const SecureStorageImpl.withStorage(this._storage);

  @override
  Future<String?> getString(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_, stack) {
      // SECURITY: do NOT inspect — caught exception's message may carry
      // the storage key in plain text.
      Error.throwWithStackTrace(const SecureStorageException(), stack);
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_, stack) {
      // SECURITY: do NOT inspect.
      Error.throwWithStackTrace(const SecureStorageException(), stack);
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_, stack) {
      // SECURITY: do NOT inspect.
      Error.throwWithStackTrace(const SecureStorageException(), stack);
    }
  }
}
