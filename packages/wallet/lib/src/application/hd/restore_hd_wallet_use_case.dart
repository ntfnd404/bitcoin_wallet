import 'package:keys/keys.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet/src/domain/entity/wallet.dart';
import 'package:wallet/src/domain/repository/hd_wallet_repository.dart';

/// Restores an HD wallet from an existing BIP39 mnemonic.
///
/// Throws [ArgumentError] if [mnemonic] fails BIP39 checksum validation.
final class RestoreHdWalletUseCase {
  final Bip39Service _bip39;
  final SeedRepository _seedRepository;
  final HdWalletRepository _hdWalletRepository;

  const RestoreHdWalletUseCase({
    required Bip39Service bip39Service,
    required SeedRepository seedRepository,
    required HdWalletRepository hdWalletRepository,
  }) : _bip39 = bip39Service,
       _seedRepository = seedRepository,
       _hdWalletRepository = hdWalletRepository;

  Future<HdWallet> call(String name, Mnemonic mnemonic) async {
    if (!_bip39.validateMnemonic(mnemonic)) {
      throw ArgumentError('Invalid BIP39 mnemonic');
    }
    final wallet = HdWallet(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now().toUtc(),
    );
    await _seedRepository.storeSeed(wallet.id, mnemonic);
    await _hdWalletRepository.saveWallet(wallet);

    return wallet;
  }
}
