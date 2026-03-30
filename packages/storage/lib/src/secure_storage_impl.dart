import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage.dart';

/// [SecureStorage] backed by [FlutterSecureStorage].
final class SecureStorageImpl implements SecureStorage {
  SecureStorageImpl() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getString(String key) => _storage.read(key: key);

  @override
  Future<void> setString(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> remove(String key) => _storage.delete(key: key);
}
