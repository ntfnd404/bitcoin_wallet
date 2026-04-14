import 'package:domain/domain.dart';

/// Retrieves the stored mnemonic for an HD wallet.
///
/// Returns `null` if no seed is stored for [walletId].
final class GetSeedUseCase {
  final SeedRepository _seed;

  const GetSeedUseCase({required SeedRepository seedRepository})
      : _seed = seedRepository;

  Future<Mnemonic?> call(String walletId) => _seed.getSeed(walletId);
}
