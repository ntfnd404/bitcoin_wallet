import 'package:keys/keys.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet/src/domain/entities/wallet.dart';
import 'package:wallet/src/domain/exceptions/wallet_exception.dart';
import 'package:wallet/src/domain/repositories/hd_wallet_repository.dart';

/// Restores an HD wallet from an existing BIP39 mnemonic.
///
/// Throws [WalletInvalidMnemonicException] if [mnemonic] fails BIP39 validation.
/// Throws [WalletStorageException] if the seed or wallet cannot be persisted.
final class RestoreHdWalletUseCase {
  final Bip39Service _bip39;
  final SeedRepository _seedRepository;
  final HdWalletRepository _hdWalletRepository;

  const RestoreHdWalletUseCase({
    required Bip39Service bip39Service,
    required this._seedRepository,
    required this._hdWalletRepository,
  }) : _bip39 = bip39Service;

  Future<HdWallet> call(String name, Mnemonic mnemonic) async {
    if (!_bip39.validateMnemonic(mnemonic)) {
      throw const WalletInvalidMnemonicException();
    }
    try {
      final wallet = HdWallet(
        id: const Uuid().v4(),
        name: name,
        createdAt: DateTime.now().toUtc(),
      );
      await _seedRepository.storeSeed(wallet.id, mnemonic);
      await _hdWalletRepository.saveWallet(wallet);

      return wallet;
    } on KeysStorageException catch (_, stack) {
      // Translate keys-bounded-context language to wallet's.
      Error.throwWithStackTrace(const WalletStorageException(), stack);
    } on WalletException {
      // Already in wallet's language — pass through unchanged.
      rethrow;
    }
    // Programmer errors propagate naturally to the zone error handler.
  }
}
