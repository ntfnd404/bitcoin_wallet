import 'package:keys/src/domain/entity/mnemonic.dart';
import 'package:keys/src/domain/exception/keys_exception.dart';
import 'package:keys/src/domain/repository/seed_repository.dart';

/// Returns the mnemonic seed for [walletId].
///
/// Throws [KeysSeedNotFoundException] if no seed exists for [walletId].
/// Throws [KeysStorageException] if secure storage fails.
final class GetSeedUseCase {
  final SeedRepository _repository;

  const GetSeedUseCase({required SeedRepository repository}) : _repository = repository;

  Future<Mnemonic> call(String walletId) async {
    final mnemonic = await _repository.getSeed(walletId);
    if (mnemonic == null) throw const KeysSeedNotFoundException();

    return mnemonic;
  }
}
