import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:storage/storage.dart';

/// Persists wallet metadata and addresses in [SecureStorage].
///
/// Follows the domain-specific storage wrapper pattern:
/// encapsulates key prefixing, JSON serialization, and index management.
/// Both [NodeWalletRepositoryImpl] and [HdWalletRepositoryImpl] delegate
/// all persistence through this class (SRP).
final class WalletLocalStore {
  const WalletLocalStore({
    required SecureStorage storage,
    required String keyPrefix,
  }) : _storage = storage,
       _keyPrefix = keyPrefix;

  final SecureStorage _storage;
  final String _keyPrefix;

  String get _indexKey => '${_keyPrefix}index';

  // ---------------------------------------------------------------------------
  // Wallets
  // ---------------------------------------------------------------------------

  /// Returns all wallets stored under this prefix.
  Future<List<Wallet>> getWallets() async {
    final ids = await _readIndex();
    final wallets = <Wallet>[];
    for (final id in ids) {
      final raw = await _storage.getString('${_keyPrefix}wallet_$id');
      if (raw == null) continue;
      wallets.add(_walletFromJson(raw));
    }

    return wallets;
  }

  /// Persists [wallet] metadata and adds its id to the index.
  Future<void> saveWallet(Wallet wallet) async {
    await _storage.setString(
      '${_keyPrefix}wallet_${wallet.id}',
      _walletToJson(wallet),
    );
    final ids = await _readIndex();
    if (!ids.contains(wallet.id)) {
      ids.add(wallet.id);
      await _writeIndex(ids);
    }
  }

  // ---------------------------------------------------------------------------
  // Addresses
  // ---------------------------------------------------------------------------

  /// Returns all addresses for [walletId].
  Future<List<Address>> getAddresses(String walletId) async {
    final raw = await _storage.getString('${_keyPrefix}addresses_$walletId');
    if (raw == null) return const [];

    return (jsonDecode(raw) as List<Object?>).cast<Map<String, Object?>>().map(_addressFromMap).toList();
  }

  /// Appends [address] to the stored list for its wallet.
  Future<void> saveAddress(Address address) async {
    final key = '${_keyPrefix}addresses_${address.walletId}';
    final raw = await _storage.getString(key);
    final list = raw == null
        ? <Map<String, Object?>>[]
        : (jsonDecode(raw) as List<Object?>).cast<Map<String, Object?>>();
    list.add(_addressToMap(address));
    await _storage.setString(key, jsonEncode(list));
  }

  /// Returns the next sequential address index for [walletId].
  Future<int> nextAddressIndex(String walletId) async {
    final raw = await _storage.getString('${_keyPrefix}addresses_$walletId');
    if (raw == null) return 0;
    return (jsonDecode(raw) as List<Object?>).length;
  }

  // ---------------------------------------------------------------------------
  // Index helpers
  // ---------------------------------------------------------------------------

  Future<List<String>> _readIndex() async {
    final raw = await _storage.getString(_indexKey);
    if (raw == null) return <String>[];

    return (jsonDecode(raw) as List<Object?>).cast<String>();
  }

  Future<void> _writeIndex(List<String> ids) => _storage.setString(_indexKey, jsonEncode(ids));

  // ---------------------------------------------------------------------------
  // JSON serialization
  // ---------------------------------------------------------------------------

  String _walletToJson(Wallet w) => jsonEncode({
    'id': w.id,
    'name': w.name,
    'type': w.type.name,
    'createdAt': w.createdAt.toIso8601String(),
  });

  Wallet _walletFromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, Object?>;

    return Wallet(
      id: map['id'] as String,
      name: map['name'] as String,
      type: WalletType.values.byName(map['type'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, Object?> _addressToMap(Address a) => {
    'value': a.value,
    'type': a.type.name,
    'walletId': a.walletId,
    'index': a.index,
    if (a.derivationPath != null) 'derivationPath': a.derivationPath,
  };

  Address _addressFromMap(Map<String, Object?> map) => Address(
    value: map['value'] as String,
    type: AddressType.values.byName(map['type'] as String),
    walletId: map['walletId'] as String,
    index: map['index'] as int,
    derivationPath: map['derivationPath'] as String?,
  );
}
