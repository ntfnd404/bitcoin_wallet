import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fake_secure_storage.dart';

WalletRepositoryImpl _makeRepo() => WalletRepositoryImpl(
      localDataSource: WalletLocalDataSourceImpl(
        storage: FakeSecureStorage(),
        mapper: const WalletMapperImpl(),
        keyPrefix: 'wallet_',
      ),
    );

Wallet _wallet({String id = 'w1', WalletType type = WalletType.hd}) => Wallet(
      id: id,
      name: 'Test $id',
      type: type,
      createdAt: DateTime.utc(2024),
    );

void main() {
  group('WalletRepositoryImpl', () {
    test('returns empty list initially', () async {
      expect(await _makeRepo().getWallets(), isEmpty);
    });

    test('persists and returns a saved wallet', () async {
      final repo = _makeRepo();
      final w = _wallet();
      await repo.saveWallet(w);
      final wallets = await repo.getWallets();

      expect(wallets, hasLength(1));
      expect(wallets.first.id, w.id);
      expect(wallets.first.type, WalletType.hd);
    });

    test('stores wallets of both types', () async {
      final repo = _makeRepo();
      await repo.saveWallet(_wallet(id: 'hd1'));
      await repo.saveWallet(_wallet(id: 'node1', type: WalletType.node));

      expect(await repo.getWallets(), hasLength(2));
    });

    test('overwrites wallet with same id', () async {
      final repo = _makeRepo();
      await repo.saveWallet(_wallet());
      await repo.saveWallet(_wallet());

      expect(await repo.getWallets(), hasLength(1));
    });
  });
}
