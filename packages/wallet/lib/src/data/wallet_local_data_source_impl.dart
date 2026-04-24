import 'dart:convert';

import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/src/data/wallet_mapper.dart';
import 'package:wallet/src/domain/data_sources/wallet_local_data_source.dart';
import 'package:wallet/src/domain/entity/wallet.dart';

/// Persists wallet metadata in [SecureStorage].
///
/// All wallets are stored as a JSON array under a single key [_key].
/// Follows the same storage pattern as [AddressLocalDataSourceImpl].
final class WalletLocalDataSourceImpl implements WalletLocalDataSource {
  static const String _key = 'wallets';

  final SecureStorage _storage;
  final WalletMapper _mapper;

  const WalletLocalDataSourceImpl({
    required SecureStorage storage,
    required WalletMapper mapper,
  }) : _storage = storage,
       _mapper = mapper;

  @override
  Future<List<Wallet>> getWallets() async {
    final raw = await _storage.getString(_key);
    if (raw == null) return const [];

    final jsonList = jsonDecode(raw) as List<Object?>;

    return jsonList.cast<Map<String, Object?>>().map<Wallet>(_mapper.decode).toList();
  }

  @override
  Future<void> saveWallet(Wallet wallet) async {
    final raw = await _storage.getString(_key);

    final List<Map<String, Object?>> list = raw == null
        ? <Map<String, Object?>>[]
        : (jsonDecode(raw) as List).cast<Map<String, Object?>>();

    final index = list.indexWhere((m) => m['id'] == wallet.id);
    final encoded = _mapper.encode(wallet);

    if (index == -1) {
      list.add(encoded);
    } else {
      list[index] = encoded;
    }

    await _storage.setString(_key, jsonEncode(list));
  }
}
