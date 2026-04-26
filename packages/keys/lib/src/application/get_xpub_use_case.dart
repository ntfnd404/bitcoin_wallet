import 'package:keys/src/domain/entity/account_xpub.dart';
import 'package:keys/src/domain/repository/seed_repository.dart';
import 'package:keys/src/domain/service/key_derivation_service.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// Returns the account-level xpub for a wallet and address type.
final class GetXpubUseCase {
  final SeedRepository _seedRepository;
  final KeyDerivationService _derivation;

  const GetXpubUseCase({
    required SeedRepository seedRepository,
    required KeyDerivationService derivation,
  }) : _seedRepository = seedRepository,
       _derivation = derivation;

  Future<AccountXpub> call(String walletId, AddressType type) async {
    final mnemonic = await _seedRepository.getSeed(walletId);
    if (mnemonic == null) {
      throw StateError('No seed found for wallet $walletId');
    }

    return _derivation.deriveAccountXpub(mnemonic, type);
  }
}
