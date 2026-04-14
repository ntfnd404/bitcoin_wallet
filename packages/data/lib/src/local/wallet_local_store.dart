import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:storage/storage.dart';

import 'wallet_mapper.dart';

/// Persists wallet metadata in [SecureStorage].
///
/// Single responsibility: CRUD operations and index management for wallets.
/// Address persistence is handled by [AddressLocalStore].
final class WalletLocalStore {
  final SecureStorage _storage;
  final String _keyPrefix;

  String get _indexKey => '${_keyPrefix}index';

  const WalletLocalStore({
    required SecureStorage storage,
    required String keyPrefix,
  }) : _storage = storage,
       _keyPrefix = keyPrefix;

  /// Returns all wallets stored under this prefix.
  Future<List<Wallet>> getWallets() async {
    final ids = await _readIndex();
    final wallets = <Wallet>[];
    for (final id in ids) {
      final raw = await _storage.getString(_walletKey(id));
      if (raw == null) continue;
      wallets.add(WalletMapper.fromJson(raw));
    }

    return wallets;
  }

  /// Persists [wallet] metadata and adds its id to the index.
  Future<void> saveWallet(Wallet wallet) async {
    await _storage.setString(
      _walletKey(wallet.id),
      WalletMapper.toJson(wallet),
    );
    final ids = await _readIndex();
    if (!ids.contains(wallet.id)) {
      ids.add(wallet.id);
      await _writeIndex(ids);
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _walletKey(String walletId) => '${_keyPrefix}wallet_$walletId';

  Future<List<String>> _readIndex() async {
    final raw = await _storage.getString(_indexKey);
    if (raw == null) return <String>[];

    return (jsonDecode(raw) as List<Object?>).cast<String>();
  }

  Future<void> _writeIndex(List<String> ids) =>
      _storage.setString(_indexKey, jsonEncode(ids));
}
