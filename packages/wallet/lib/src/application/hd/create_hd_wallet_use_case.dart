import 'package:keys/keys.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet/src/domain/entities/wallet.dart';
import 'package:wallet/src/domain/exceptions/wallet_exception.dart';
import 'package:wallet/src/domain/repositories/hd_wallet_repository.dart';

/// Creates a new HD wallet: generates a mnemonic, stores the seed,
/// persists wallet metadata, and returns both.
///
/// ID generation lives here (Application layer) — not in the repository.
///
/// Throws [WalletStorageException] if the seed or wallet cannot be persisted.
final class CreateHdWalletUseCase {
  final Bip39Service _bip39;
  final SeedRepository _seedRepository;
  final HdWalletRepository _hdWalletRepository;

  const CreateHdWalletUseCase({
    required Bip39Service bip39Service,
    required this._seedRepository,
    required this._hdWalletRepository,
  }) : _bip39 = bip39Service;

  Future<(HdWallet, Mnemonic)> call(String name, {int wordCount = 12}) async {
    try {
      final mnemonic = _bip39.generateMnemonic(wordCount: wordCount);
      final wallet = HdWallet(
        id: const Uuid().v4(),
        name: name,
        createdAt: DateTime.now().toUtc(),
      );
      await _seedRepository.storeSeed(wallet.id, mnemonic);
      await _hdWalletRepository.saveWallet(wallet);

      return (wallet, mnemonic);
    } on KeysStorageException catch (_, stack) {
      // Translate keys-bounded-context language to wallet's.
      Error.throwWithStackTrace(const WalletStorageException(), stack);
    } on WalletException {
      // Already in wallet's language — pass through unchanged.
      rethrow;
    }
    // Programmer errors (TypeError, RangeError, etc.) propagate naturally
    // to the zone error handler — they must NOT be masked as storage errors.
  }
}
