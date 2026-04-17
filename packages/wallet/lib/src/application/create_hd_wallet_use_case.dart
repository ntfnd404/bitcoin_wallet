import 'package:keys/keys.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet/src/domain/entity/wallet.dart';
import 'package:wallet/src/domain/entity/wallet_type.dart';
import 'package:wallet/src/domain/repository/wallet_repository.dart';

/// Creates a new HD wallet: generates a mnemonic, stores the seed,
/// persists wallet metadata, and returns both.
///
/// ID generation lives here (Application layer) — not in the repository.
final class CreateHdWalletUseCase {
  final Bip39Service _bip39;
  final SeedRepository _seedRepository;
  final WalletRepository _walletRepository;

  const CreateHdWalletUseCase({
    required Bip39Service bip39Service,
    required SeedRepository seedRepository,
    required WalletRepository walletRepository,
  }) : _bip39 = bip39Service,
       _seedRepository = seedRepository,
       _walletRepository = walletRepository;

  Future<(Wallet, Mnemonic)> call(String name, {int wordCount = 12}) async {
    final mnemonic = _bip39.generateMnemonic(wordCount: wordCount);
    final wallet = Wallet(
      id: const Uuid().v4(),
      name: name,
      type: WalletType.hd,
      createdAt: DateTime.now().toUtc(),
    );
    await _seedRepository.storeSeed(wallet.id, mnemonic);
    await _walletRepository.saveWallet(wallet);

    return (wallet, mnemonic);
  }
}
