import 'dart:convert';

import 'package:data/src/mappers/wallet_mapper.dart';
import 'package:domain/domain.dart';
import 'package:storage/storage.dart';

/// Persists wallet metadata in [SecureStorage].
///
/// Single responsibility: CRUD operations and index management for wallets.
/// Address persistence is handled by [AddressLocalDataSourceImpl].
/// Implements [WalletLocalDataSource] from domain.
final class WalletLocalDataSourceImpl implements WalletLocalDataSource {
  final SecureStorage _storage;
  final WalletMapper _mapper;
  final String _keyPrefix;

  String get _indexKey => '${_keyPrefix}index';

  const WalletLocalDataSourceImpl({
    required SecureStorage storage,
    required WalletMapper mapper,
    required String keyPrefix,
  }) : _storage = storage,
       _mapper = mapper,
       _keyPrefix = keyPrefix;

  /// Returns all wallets stored under this prefix.
  @override
  Future<List<Wallet>> getWallets() async {
    final ids = await _readIndex();
    final wallets = <Wallet>[];
    for (final id in ids) {
      final raw = await _storage.getString(_walletKey(id));
      if (raw == null) continue;
      final map = jsonDecode(raw) as Map<String, Object?>;
      wallets.add(_mapper.decode(map));
    }

    return wallets;
  }

  /// Persists [wallet] metadata and adds its id to the index.
  @override
  Future<void> saveWallet(Wallet wallet) async {
    final map = _mapper.encode(wallet);
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
