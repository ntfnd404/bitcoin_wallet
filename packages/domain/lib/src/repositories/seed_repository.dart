import 'package:domain/src/entities/mnemonic.dart';

abstract interface class SeedRepository {
  /// Persists [mnemonic] for [walletId] in secure storage.
  ///
  /// Overwrites any existing seed for this wallet.
  Future<void> storeSeed(String walletId, Mnemonic mnemonic);

  /// Returns the [Mnemonic] for [walletId], or `null` if none is stored.
  Future<Mnemonic?> getSeed(String walletId);

  /// Deletes the stored seed for [walletId]. No-op if absent.
  Future<void> deleteSeed(String walletId);
}
