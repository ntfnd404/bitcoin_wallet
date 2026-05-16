import 'package:keys/keys.dart';

/// In-memory seed repository for unit tests.
final class FakeSeedRepository implements SeedRepository {
  Object? throwOnStoreSeed;

  final Map<String, Mnemonic> _seeds = {};

  Map<String, Mnemonic> get seeds => Map.unmodifiable(_seeds);

  @override
  Future<void> storeSeed(String walletId, Mnemonic mnemonic) async {
    final toThrow = throwOnStoreSeed;
    if (toThrow != null) throw toThrow;
    _seeds[walletId] = mnemonic;
  }

  @override
  Future<Mnemonic?> getSeed(String walletId) async => _seeds[walletId];

  @override
  Future<void> deleteSeed(String walletId) async => _seeds.remove(walletId);
}
