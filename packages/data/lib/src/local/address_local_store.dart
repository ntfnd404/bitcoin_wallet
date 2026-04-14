import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:storage/storage.dart';

import 'address_mapper.dart';

/// Persists addresses in [SecureStorage].
///
/// Each wallet has its own address list, keyed by walletId.
/// Index management is handled automatically.
final class AddressLocalStore {
  final SecureStorage _storage;
  final String _keyPrefix;

  const AddressLocalStore({
    required SecureStorage storage,
    required String keyPrefix,
  }) : _storage = storage,
       _keyPrefix = keyPrefix;

  /// Returns all addresses for [walletId].
  Future<List<Address>> getAddresses(String walletId) async {
    final raw = await _storage.getString(_addressesKey(walletId));
    if (raw == null) return const [];

    return (jsonDecode(raw) as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(AddressMapper.fromMap)
        .toList();
  }

  /// Appends [address] to the stored list for its wallet.
  Future<void> saveAddress(Address address) async {
    final key = _addressesKey(address.walletId);
    final raw = await _storage.getString(key);
    final list = raw == null
        ? <Map<String, Object?>>[]
        : (jsonDecode(raw) as List<Object?>).cast<Map<String, Object?>>();
    list.add(AddressMapper.toMap(address));
    await _storage.setString(key, jsonEncode(list));
  }

  /// Returns the next sequential address index for [walletId].
  Future<int> nextAddressIndex(String walletId) async {
    final raw = await _storage.getString(_addressesKey(walletId));
    if (raw == null) return 0;

    return (jsonDecode(raw) as List<Object?>).length;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _addressesKey(String walletId) => '${_keyPrefix}addresses_$walletId';
}
