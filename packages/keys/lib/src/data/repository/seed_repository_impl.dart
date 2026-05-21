import 'package:keys/src/domain/entity/mnemonic.dart';
import 'package:keys/src/domain/exception/keys_exception.dart';
import 'package:keys/src/domain/repository/seed_repository.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// Persists BIP39 mnemonics in [SecureStorage].
/// Key format: `seed_<walletId>`. Value: space-joined word list.
///
/// SECURITY: every infra failure is wrapped in [KeysStorageException]
/// (zero-arg). Catch variable is `_` — caught exception (may be
/// [SecureStorageException], `PlatformException`, or unexpected) is NOT
/// inspected because its `toString()` may carry the storage key
/// (`seed_<walletId>`). Original cause preserved in stack trace only via
/// [Error.throwWithStackTrace].
final class SeedRepositoryImpl implements SeedRepository {
  final SecureStorage _storage;

  const SeedRepositoryImpl({required this._storage});

  @override
  Future<void> storeSeed(String walletId, Mnemonic mnemonic) async {
    try {
      await _storage.setString(_key(walletId), mnemonic.words.join(' '));
    } catch (_, stack) {
      // SECURITY: do NOT inspect — storage key may carry walletId.
      Error.throwWithStackTrace(const KeysStorageException(), stack);
    }
  }

  @override
  Future<Mnemonic?> getSeed(String walletId) async {
    try {
      final raw = await _storage.getString(_key(walletId));
      if (raw == null) return null;

      return Mnemonic(words: List.unmodifiable(raw.split(' ')));
    } catch (_, stack) {
      // SECURITY: do NOT inspect.
      Error.throwWithStackTrace(const KeysStorageException(), stack);
    }
  }

  @override
  Future<void> deleteSeed(String walletId) async {
    try {
      await _storage.remove(_key(walletId));
    } catch (_, stack) {
      // SECURITY: do NOT inspect.
      Error.throwWithStackTrace(const KeysStorageException(), stack);
    }
  }

  static String _key(String walletId) => 'seed_$walletId';
}
