import 'package:keys/keys.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet/src/domain/entity/wallet.dart';
import 'package:wallet/src/domain/entity/wallet_type.dart';
import 'package:wallet/src/domain/repository/wallet_repository.dart';

/// Restores an HD wallet from an existing BIP39 mnemonic.
///
/// Throws [ArgumentError] if [mnemonic] fails BIP39 checksum validation.
final class RestoreHdWalletUseCase {
  final Bip39Service _bip39;
  final SeedRepository _seedRepository;
  final WalletRepository _walletRepository;

  const RestoreHdWalletUseCase({
    required Bip39Service bip39Service,
    required SeedRepository seedRepository,
    required WalletRepository walletRepository,
  }) : _bip39 = bip39Service,
       _seedRepository = seedRepository,
       _walletRepository = walletRepository;

  Future<Wallet> call(String name, Mnemonic mnemonic) async {
    if (!_bip39.validateMnemonic(mnemonic)) {
      throw ArgumentError('Invalid BIP39 mnemonic');
    }
    final wallet = Wallet(
      id: const Uuid().v4(),
      name: name,
      type: WalletType.hd,
      createdAt: DateTime.now().toUtc(),
    );
    await _seedRepository.storeSeed(wallet.id, mnemonic);
    await _walletRepository.saveWallet(wallet);

    return wallet;
  }
}
