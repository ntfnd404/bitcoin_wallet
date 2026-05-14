import 'package:keys/src/domain/entity/mnemonic.dart';
import 'package:keys/src/domain/repository/seed_repository.dart';

/// Package-local fake seed repository for unit tests in the `keys` package.
///
/// Cannot import from the app's `test/` directory; this mirrors the interface.
final class FakeSeedRepository implements SeedRepository {
  final Map<String, Mnemonic> _seeds = {};

  void storeSeedSync(String walletId, Mnemonic mnemonic) {
    _seeds[walletId] = mnemonic;
  }

  @override
  Future<void> storeSeed(String walletId, Mnemonic mnemonic) async {
    _seeds[walletId] = mnemonic;
  }

  @override
  Future<Mnemonic?> getSeed(String walletId) async => _seeds[walletId];

  @override
  Future<void> deleteSeed(String walletId) async => _seeds.remove(walletId);
}
