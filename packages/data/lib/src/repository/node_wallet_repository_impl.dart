import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:storage/storage.dart';
import 'package:uuid/uuid.dart';

final class NodeWalletRepositoryImpl implements WalletRepository {
  const NodeWalletRepositoryImpl({
    required BitcoinRpcClient rpcClient,
    required SecureStorage storage,
  })  : _rpcClient = rpcClient,
        _storage = storage;

  final BitcoinRpcClient _rpcClient;
  final SecureStorage _storage;

  static const _uuid = Uuid();
  static const _indexKey = 'node_wallets_index';

  @override
  Future<List<Wallet>> getWallets() async {
    final raw = await _storage.read(_indexKey);
    if (raw == null) return const [];
    final ids = (jsonDecode(raw) as List<Object?>).cast<String>();
    final wallets = <Wallet>[];
    for (final id in ids) {
      final data = await _storage.read('node_wallet_$id');
      if (data == null) continue;
      wallets.add(_walletFromMap(jsonDecode(data) as Map<String, Object?>));
    }
    return wallets;
  }

  @override
  Future<Wallet> createNodeWallet(String name) async {
    await _rpcClient.call('createwallet', [name]);
    final wallet = Wallet(
      id: _uuid.v4(),
      name: name,
      type: WalletType.node,
      createdAt: DateTime.now().toUtc(),
    );
    await _saveWallet(wallet);
    return wallet;
  }

  @override
  Future<Address> generateAddress(Wallet wallet, AddressType type) async {
    final result = await _rpcClient.call(
      'getnewaddress',
      ['', _rpcAddressType(type)],
      wallet.name,
    );
    final value = result as String;
    final index = await _nextAddressIndex(wallet.id);
    final address = Address(
      value: value,
      type: type,
      walletId: wallet.id,
      index: index,
    );
    await _saveAddress(address);
    return address;
  }

  @override
  Future<List<Address>> getAddresses(Wallet wallet) async {
    final raw = await _storage.read('node_addresses_${wallet.id}');
    if (raw == null) return const [];
    return (jsonDecode(raw) as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(_addressFromMap)
        .toList();
  }

  @override
  Future<(Wallet, Mnemonic)> createHDWallet(
    String name, {
    int wordCount = 12,
  }) =>
      throw UnsupportedError(
        'NodeWalletRepositoryImpl does not support HD wallets',
      );

  @override
  Future<Wallet> restoreHDWallet(String name, Mnemonic mnemonic) =>
      throw UnsupportedError(
        'NodeWalletRepositoryImpl does not support HD wallets',
      );

  // --- private helpers ---

  String _rpcAddressType(AddressType type) => switch (type) {
        AddressType.legacy => 'legacy',
        AddressType.wrappedSegwit => 'p2sh-segwit',
        AddressType.nativeSegwit => 'bech32',
        AddressType.taproot => 'bech32m',
      };

  Future<void> _saveWallet(Wallet wallet) async {
    await _storage.write(
      'node_wallet_${wallet.id}',
      jsonEncode(_walletToMap(wallet)),
    );
    final raw = await _storage.read(_indexKey);
    final ids = raw == null
        ? <String>[]
        : (jsonDecode(raw) as List<Object?>).cast<String>();
    if (!ids.contains(wallet.id)) {
      ids.add(wallet.id);
      await _storage.write(_indexKey, jsonEncode(ids));
    }
  }

  Future<void> _saveAddress(Address address) async {
    final key = 'node_addresses_${address.walletId}';
    final raw = await _storage.read(key);
    final list = raw == null
        ? <Map<String, Object?>>[]
        : (jsonDecode(raw) as List<Object?>).cast<Map<String, Object?>>();
    list.add(_addressToMap(address));
    await _storage.write(key, jsonEncode(list));
  }

  Future<int> _nextAddressIndex(String walletId) async {
    final raw = await _storage.read('node_addresses_$walletId');
    if (raw == null) return 0;
    return (jsonDecode(raw) as List<Object?>).length;
  }

  Wallet _walletFromMap(Map<String, Object?> map) => Wallet(
        id: map['id'] as String,
        name: map['name'] as String,
        type: WalletType.node,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Map<String, Object?> _walletToMap(Wallet w) => {
        'id': w.id,
        'name': w.name,
        'createdAt': w.createdAt.toIso8601String(),
      };

  Address _addressFromMap(Map<String, Object?> map) => Address(
        value: map['value'] as String,
        type: AddressType.values.byName(map['type'] as String),
        walletId: map['walletId'] as String,
        index: map['index'] as int,
      );

  Map<String, Object?> _addressToMap(Address a) => {
        'value': a.value,
        'type': a.type.name,
        'walletId': a.walletId,
        'index': a.index,
      };
}
