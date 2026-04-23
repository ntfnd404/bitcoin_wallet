import 'dart:convert';

import 'package:address/src/data/address_mapper.dart';
import 'package:address/src/domain/data_sources/address_local_data_source.dart';
import 'package:address/src/domain/entity/address.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// Persists addresses in [SecureStorage].
///
/// Each wallet has its own address list, keyed by walletId.
/// Index management is handled automatically.
final class AddressLocalDataSourceImpl implements AddressLocalDataSource {
  static const String _keyPrefix = 'address_';

  final SecureStorage _storage;
  final AddressMapper _mapper;

  const AddressLocalDataSourceImpl({
    required SecureStorage storage,
    required AddressMapper mapper,
  }) : _mapper = mapper,
       _storage = storage;

  @override
  Future<List<Address>> getAddresses(String walletId) async {
    final key = _addressesKey(walletId);
    final raw = await _storage.getString(key);
    if (raw == null) return const [];

    final jsonList = jsonDecode(raw) as List<Object?>;

    return jsonList.cast<Map<String, Object?>>().map<Address>(_mapper.decode).toList();
  }

  @override
  Future<void> saveAddress(Address address) async {
    final key = _addressesKey(address.walletId);
    final raw = await _storage.getString(key);

    final List<Map<String, Object?>> list = raw == null
        ? <Map<String, Object?>>[]
        : (jsonDecode(raw) as List).cast<Map<String, Object?>>();

    list.add(_mapper.encode(address));

    await _storage.setString(key, jsonEncode(list));
  }

  @override
  Future<int> nextAddressIndex(String walletId) async {
    final raw = await _storage.getString(_addressesKey(walletId));
    if (raw == null) return 0;

    return (jsonDecode(raw) as List<Object?>).length;
  }

  String _addressesKey(String walletId) => '${_keyPrefix}addresses_$walletId';
}
