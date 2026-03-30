# Plan: BW-0001 Phase 3 — Data: RPC & Node Wallet

Status: `PLAN_APPROVED`
Ticket: BW-0001

---

## Overview

Implement `SecureStorage` adapter and `NodeWalletRepositoryImpl`.
Wire `NodeWalletRepositoryImpl` into `AppDependenciesBuilder`.

**Package rules:**
- `packages/storage` depends only on `flutter_secure_storage`
- `packages/data` depends on `domain`, `rpc_client`, `storage` — no direct Flutter SDK import in impl files

---

## Implementation order

1. Fix `packages/storage/pubspec.yaml` — exact version for `flutter_secure_storage`
2. Fix `packages/data/pubspec.yaml` — exact versions for `crypto`, `pointycastle`
3. `3.1` — harden `SecureStorage` (final class, instance storage field)
4. `3.2` — `NodeWalletRepositoryImpl`
5. Uncomment export in `packages/data/lib/data.dart`
6. Update `lib/core/di/app_dependencies_builder.dart` — wire `NodeWalletRepositoryImpl`
7. `flutter analyze` — zero warnings
8. `3.3` — integration test

---

## Files to update

### `packages/storage/pubspec.yaml`

Find exact version of `flutter_secure_storage`:
```sh
dart pub deps --json | grep flutter_secure_storage
# or check pubspec.lock
```

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_secure_storage: 9.2.4   # exact version from pubspec.lock
```

### `packages/data/pubspec.yaml`

Fix `any` to exact versions from pubspec.lock:
```yaml
dependencies:
  crypto: 3.0.7           # exact
  domain:
    path: ../domain
  flutter:
    sdk: flutter
  pointycastle: 4.0.0     # exact
  rpc_client:
    path: ../rpc_client
  storage:
    path: ../storage
```

### `packages/storage/lib/src/secure_storage.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class SecureStorage {
  const SecureStorage() : _storage = const FlutterSecureStorage();

  const SecureStorage.withStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);
}
```

### `packages/data/lib/src/repository/node_wallet_repository_impl.dart`

```dart
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
      final map = jsonDecode(data) as Map<String, Object?>;
      wallets.add(_walletFromMap(map));
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
      walletName: wallet.name,
    );
    final value = result['result'] as String;
    final address = Address(
      value: value,
      type: type,
      walletId: wallet.id,
      index: await _nextAddressIndex(wallet.id),
    );
    await _saveAddress(address);
    return address;
  }

  @override
  Future<List<Address>> getAddresses(Wallet wallet) async {
    final raw = await _storage.read('node_addresses_${wallet.id}');
    if (raw == null) return const [];
    final list = (jsonDecode(raw) as List<Object?>);
    return list
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

  // --- helpers ---

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
```

**Note:** `BitcoinRpcClient.call` needs a `walletName` optional param so it can call
`/wallet/<name>` endpoint. Check current signature and add if missing.

### `packages/data/lib/data.dart`

Uncomment `node_wallet_repository_impl.dart`:
```dart
export 'src/repository/node_wallet_repository_impl.dart';
// export 'src/repository/hd_wallet_repository_impl.dart';
// export 'src/repository/seed_repository_impl.dart';
// export 'src/service/bip39_service_impl.dart';
// export 'src/service/key_derivation_service_impl.dart';
```

### `lib/core/di/app_dependencies_builder.dart`

Replace `_StubWalletRepository` with `NodeWalletRepositoryImpl`:
```dart
import 'package:data/data.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:storage/storage.dart';

// ...

AppDependencies build() {
  final rpcClient = BitcoinRpcClient(
    url: AppConstants.rpcUrl,
    username: AppConstants.rpcUser,
    password: AppConstants.rpcPassword,
  );
  final storage = const SecureStorage();
  return AppDependencies(
    walletRepository: NodeWalletRepositoryImpl(
      rpcClient: rpcClient,
      storage: storage,
    ),
    seedRepository: _StubSeedRepository(),
    bip39Service: _StubBip39Service(),
    keyDerivationService: _StubKeyDerivationService(),
  );
}
```

---

## Integration test

### `packages/data/test/node_wallet_repository_impl_integration_test.dart`

```dart
// Requires: live regtest node at 127.0.0.1:18443 (bitcoin:bitcoin)
// Run: dart test packages/data/test/ --tags integration

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:test/test.dart';

void main() {
  group('NodeWalletRepositoryImpl', () {
    late NodeWalletRepositoryImpl repo;

    setUp(() {
      repo = NodeWalletRepositoryImpl(
        rpcClient: BitcoinRpcClient(
          url: 'http://127.0.0.1:18443',
          username: 'bitcoin',
          password: 'bitcoin',
        ),
        storage: InMemoryStorage(), // test double
      );
    });

    test('createNodeWallet creates wallet on Bitcoin Core', () async {
      final wallet = await repo.createNodeWallet('test_wallet_${DateTime.now().millisecondsSinceEpoch}');
      expect(wallet.type, WalletType.node);
      expect(wallet.name, isNotEmpty);
    });

    test('generateAddress returns correct regtest prefixes', () async {
      final wallet = await repo.createNodeWallet('addr_test_${DateTime.now().millisecondsSinceEpoch}');

      final legacy = await repo.generateAddress(wallet, AddressType.legacy);
      final wrapped = await repo.generateAddress(wallet, AddressType.wrappedSegwit);
      final native = await repo.generateAddress(wallet, AddressType.nativeSegwit);
      final taproot = await repo.generateAddress(wallet, AddressType.taproot);

      expect(legacy.value, startsWith('m'));
      expect(wrapped.value, startsWith('2'));
      expect(native.value, startsWith('bcrt1q'));
      expect(taproot.value, startsWith('bcrt1p'));
    });
  });
}
```

---

## Verification

```sh
flutter analyze          # zero warnings
flutter run -d macos     # app launches
# With regtest node running:
dart test packages/data/test/ --tags integration
```
