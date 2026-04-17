import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// [SecureStorage] backed by [FlutterSecureStorage].
final class SecureStorageImpl implements SecureStorage {
  final FlutterSecureStorage _storage;

  const SecureStorageImpl() : _storage = const FlutterSecureStorage();

  @visibleForTesting
  const SecureStorageImpl.withStorage(this._storage);

  @override
  Future<String?> getString(String key) => _storage.read(key: key);

  @override
  Future<void> setString(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> remove(String key) => _storage.delete(key: key);
}
