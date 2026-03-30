/// Integration test — requires a live Bitcoin Core regtest node.
///
/// Run with:
///   dart test packages/data/test/node_wallet_repository_impl_integration_test.dart
///
/// Prerequisites:
///   make btc-up && make btc-wallet-ready
library;

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

/// In-memory [SecureStorage] for use in tests.
final class _InMemoryStorage extends SecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write(String key, String value) async => _store[key] = value;

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> delete(String key) async => _store.remove(key);
}

NodeWalletRepositoryImpl _makeRepo() => NodeWalletRepositoryImpl(
      rpcClient: BitcoinRpcClient(
        url: 'http://127.0.0.1:18443',
        user: 'bitcoin',
        password: 'bitcoin',
      ),
      storage: _InMemoryStorage(),
    );

void main() {
  group('NodeWalletRepositoryImpl', () {
    late NodeWalletRepositoryImpl repo;

    setUp(() => repo = _makeRepo());

    test('createNodeWallet returns Wallet with node type', () async {
      final wallet = await repo.createNodeWallet(
        'test_${DateTime.now().millisecondsSinceEpoch}',
      );

      expect(wallet.type, WalletType.node);
      expect(wallet.id, isNotEmpty);
      expect(wallet.name, isNotEmpty);
    });

    test('getWallets returns previously created wallet', () async {
      final created = await repo.createNodeWallet(
        'list_${DateTime.now().millisecondsSinceEpoch}',
      );

      final wallets = await repo.getWallets();
      expect(wallets.any((w) => w.id == created.id), isTrue);
    });

    test('generateAddress returns correct regtest prefixes', () async {
      final wallet = await repo.createNodeWallet(
        'addr_${DateTime.now().millisecondsSinceEpoch}',
      );

      final legacy = await repo.generateAddress(wallet, AddressType.legacy);
      final wrapped =
          await repo.generateAddress(wallet, AddressType.wrappedSegwit);
      final native =
          await repo.generateAddress(wallet, AddressType.nativeSegwit);
      final taproot = await repo.generateAddress(wallet, AddressType.taproot);

      expect(legacy.value, startsWith('m'));
      expect(wrapped.value, startsWith('2'));
      expect(native.value, startsWith('bcrt1q'));
      expect(taproot.value, startsWith('bcrt1p'));
    });

    test('getAddresses returns all generated addresses', () async {
      final wallet = await repo.createNodeWallet(
        'addrs_${DateTime.now().millisecondsSinceEpoch}',
      );
      await repo.generateAddress(wallet, AddressType.legacy);
      await repo.generateAddress(wallet, AddressType.nativeSegwit);

      final addresses = await repo.getAddresses(wallet);
      expect(addresses, hasLength(2));
    });

    test('createHDWallet throws UnsupportedError', () {
      expect(
        () => repo.createHDWallet('hd'),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
