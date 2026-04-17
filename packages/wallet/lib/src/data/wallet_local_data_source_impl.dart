import 'dart:convert';

import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/src/data/wallet_serializer.dart';
import 'package:wallet/src/domain/data_sources/wallet_local_data_source.dart';
import 'package:wallet/src/domain/entity/wallet.dart';

/// Persists wallet metadata in [SecureStorage].
///
/// Single responsibility: CRUD operations and index management for wallets.
/// Implements [WalletLocalDataSource].
final class WalletLocalDataSourceImpl implements WalletLocalDataSource {
  final SecureStorage _storage;
  final WalletSerializer _serializer;
  final String _keyPrefix;

  String get _indexKey => '${_keyPrefix}index';

  const WalletLocalDataSourceImpl({
    required SecureStorage storage,
    required WalletSerializer serializer,
    required String keyPrefix,
  }) : _storage = storage,
       _serializer = serializer,
       _keyPrefix = keyPrefix;

  @override
  Future<List<Wallet>> getWallets() async {
    final ids = await _readIndex();
    final wallets = <Wallet>[];
    for (final id in ids) {
      final raw = await _storage.getString(_walletKey(id));
      if (raw == null) continue;
      final map = jsonDecode(raw) as Map<String, Object?>;
      wallets.add(_serializer.decode(map));
    }

    return wallets;
  }

  @override
  Future<void> saveWallet(Wallet wallet) async {
    final map = _serializer.encode(wallet);
    await _storage.setString(
      _walletKey(wallet.id),
      jsonEncode(map),
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

  Future<void> _writeIndex(List<String> ids) => _storage.setString(_indexKey, jsonEncode(ids));
}
