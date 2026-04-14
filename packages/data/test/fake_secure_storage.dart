/// Shared fake implementations for data layer unit tests.
library;

import 'package:storage/storage.dart';

/// In-memory [SecureStorage] for unit tests.
final class FakeSecureStorage implements SecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> getString(String key) async => _store[key];

  @override
  Future<void> setString(String key, String value) async => _store[key] = value;

  @override
  Future<void> remove(String key) async => _store.remove(key);
}
