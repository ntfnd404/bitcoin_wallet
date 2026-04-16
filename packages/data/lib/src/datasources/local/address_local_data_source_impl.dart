import 'dart:convert';

import 'package:data/src/mappers/address_mapper.dart';
import 'package:domain/domain.dart';
import 'package:storage/storage.dart';

/// Persists addresses in [SecureStorage].
///
/// Each wallet has its own address list, keyed by walletId.
/// Index management is handled automatically.
final class AddressLocalDataSourceImpl implements AddressLocalDataSource {
  static const String _keyPrefix = 'wallet_';

  final SecureStorage _storage;
  final AddressMapper _mapper;

  const AddressLocalDataSourceImpl({
    required SecureStorage storage,
    required AddressMapper mapper,
  }) : _mapper = mapper,
       _storage = storage;

  /// Returns all addresses for [walletId].
  @override
  Future<List<Address>> getAddresses(String walletId) async {
    final key = _addressesKey(walletId);
    final raw = await _storage.getString(key);
    if (raw == null) return const [];

    final jsonList = jsonDecode(raw) as List<Object?>;

    return jsonList
        .cast<Map<String, Object?>>()
        .map(_mapper.decode) // Map → Address
        .toList();
  }

  /// Appends [address] to the stored list for its wallet.
  @override
  Future<void> saveAddress(Address address) async {
    final key = _addressesKey(address.walletId);
    final raw = await _storage.getString(key);

    final List<Map<String, Object?>> list = raw == null
        ? <Map<String, Object?>>[]
        : (jsonDecode(raw) as List).cast<Map<String, Object?>>();

    list.add(_mapper.encode(address)); // Address → Map

    await _storage.setString(key, jsonEncode(list));
  }

  /// Returns the next sequential address index for [walletId].
  @override
  Future<int> nextAddressIndex(String walletId) async {
    final raw = await _storage.getString(_addressesKey(walletId));
    if (raw == null) return 0;

    return (jsonDecode(raw) as List<Object?>).length;
  }

  String _addressesKey(String walletId) => '${_keyPrefix}addresses_$walletId';
}
