import 'dart:convert';

import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/src/data/address_mapper.dart';
import 'package:wallet/src/domain/entity/address.dart';
import 'package:wallet/src/domain/exception/address_exception.dart';
import 'package:wallet/src/domain/repository/address_repository.dart';

final class AddressRepositoryImpl implements AddressRepository {
  static const String _keyPrefix = 'address_';

  final SecureStorage _storage;
  final AddressMapper _mapper;

  const AddressRepositoryImpl({
    required SecureStorage storage,
    required AddressMapper mapper,
  }) : _mapper = mapper,
       _storage = storage;

  @override
  Future<List<Address>> getAddresses(String walletId) async {
    try {
      final key = _addressesKey(walletId);
      final raw = await _storage.getString(key);
      if (raw == null) return const [];

      final jsonList = jsonDecode(raw) as List<Object?>;

      return jsonList.cast<Map<String, Object?>>().map<Address>(_mapper.decode).toList();
    } catch (_, stack) {
      Error.throwWithStackTrace(const AddressStorageException(), stack);
    }
  }

  @override
  Future<void> saveAddress(Address address) async {
    try {
      final key = _addressesKey(address.walletId);
      final raw = await _storage.getString(key);

      final List<Map<String, Object?>> list = raw == null
          ? <Map<String, Object?>>[]
          : (jsonDecode(raw) as List).cast<Map<String, Object?>>();

      list.add(_mapper.encode(address));

      await _storage.setString(key, jsonEncode(list));
    } catch (_, stack) {
      Error.throwWithStackTrace(const AddressStorageException(), stack);
    }
  }

  @override
  Future<int> nextAddressIndex(String walletId) async {
    try {
      final raw = await _storage.getString(_addressesKey(walletId));
      if (raw == null) return 0;

      return (jsonDecode(raw) as List<Object?>).length;
    } catch (_, stack) {
      Error.throwWithStackTrace(const AddressStorageException(), stack);
    }
  }

  String _addressesKey(String walletId) => '${_keyPrefix}addresses_$walletId';
}
