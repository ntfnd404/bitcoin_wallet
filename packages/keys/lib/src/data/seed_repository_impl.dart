import 'package:keys/src/domain/entity/mnemonic.dart';
import 'package:keys/src/domain/repository/seed_repository.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// Persists BIP39 mnemonics in [SecureStorage].
/// Key format: `seed_<walletId>`. Value: space-joined word list.
final class SeedRepositoryImpl implements SeedRepository {
  final SecureStorage _storage;

  const SeedRepositoryImpl({required SecureStorage storage}) : _storage = storage;

  @override
  Future<void> storeSeed(String walletId, Mnemonic mnemonic) =>
      _storage.setString(_key(walletId), mnemonic.words.join(' '));

  @override
  Future<Mnemonic?> getSeed(String walletId) async {
    final raw = await _storage.getString(_key(walletId));
    if (raw == null) return null;

    return Mnemonic(words: List.unmodifiable(raw.split(' ')));
  }

  @override
  Future<void> deleteSeed(String walletId) => _storage.remove(_key(walletId));

  static String _key(String walletId) => 'seed_$walletId';
}
