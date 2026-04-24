import 'package:keys/keys.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet/src/domain/entity/wallet.dart';
import 'package:wallet/src/domain/repository/hd_wallet_repository.dart';

/// Creates a new HD wallet: generates a mnemonic, stores the seed,
/// persists wallet metadata, and returns both.
///
/// ID generation lives here (Application layer) — not in the repository.
final class CreateHdWalletUseCase {
  final Bip39Service _bip39;
  final SeedRepository _seedRepository;
  final HdWalletRepository _hdWalletRepository;

  const CreateHdWalletUseCase({
    required Bip39Service bip39Service,
    required SeedRepository seedRepository,
    required HdWalletRepository hdWalletRepository,
  }) : _bip39 = bip39Service,
       _seedRepository = seedRepository,
       _hdWalletRepository = hdWalletRepository;

  Future<(HdWallet, Mnemonic)> call(String name, {int wordCount = 12}) async {
    final mnemonic = _bip39.generateMnemonic(wordCount: wordCount);
    final wallet = HdWallet(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now().toUtc(),
    );
    await _seedRepository.storeSeed(wallet.id, mnemonic);
    await _hdWalletRepository.saveWallet(wallet);

    return (wallet, mnemonic);
  }
}
