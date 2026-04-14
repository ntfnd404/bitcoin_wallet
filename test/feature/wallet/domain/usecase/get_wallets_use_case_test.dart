import 'package:bitcoin_wallet/feature/wallet/domain/usecase/get_wallets_use_case.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_wallet_repository.dart';

void main() {
  group('GetWalletsUseCase', () {
    late FakeWalletRepository walletRepo;
    late GetWalletsUseCase useCase;

    setUp(() {
      walletRepo = FakeWalletRepository();
      useCase = GetWalletsUseCase(walletRepository: walletRepo);
    });

    test('returns empty list when no wallets saved', () async {
      final wallets = await useCase();

      expect(wallets, isEmpty);
    });

    test('returns all saved wallets', () async {
      final hd = Wallet(
        id: 'hd-1',
        name: 'HD Wallet',
        type: WalletType.hd,
        createdAt: DateTime.utc(2024),
      );
      final node = Wallet(
        id: 'node-1',
        name: 'Node Wallet',
        type: WalletType.node,
        createdAt: DateTime.utc(2024),
      );
      await walletRepo.saveWallet(hd);
      await walletRepo.saveWallet(node);

      final wallets = await useCase();

      expect(wallets, hasLength(2));
      expect(wallets.map((w) => w.id), containsAll(['hd-1', 'node-1']));
    });

    test('returns wallets of both types without filtering', () async {
      final hd = Wallet(
        id: 'hd-1',
        name: 'HD',
        type: WalletType.hd,
        createdAt: DateTime.utc(2024),
      );
      final node = Wallet(
        id: 'node-1',
        name: 'Node',
        type: WalletType.node,
        createdAt: DateTime.utc(2024),
      );
      await walletRepo.saveWallet(hd);
      await walletRepo.saveWallet(node);

      final wallets = await useCase();
      final types = wallets.map((w) => w.type).toSet();

      expect(types, containsAll([WalletType.hd, WalletType.node]));
    });
  });
}
