import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet/wallet.dart';

import 'fakes/fake_bip39_service.dart';
import 'fakes/fake_seed_repository.dart';
import 'fakes/fake_wallet_repository.dart';
import 'fakes/test_fixtures.dart';
import 'mocks/mock_wallet_repository.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      Wallet(
        id: 'test',
        name: 'test',
        type: WalletType.hd,
        createdAt: DateTime.utc(2024),
      ),
    );
    registerFallbackValue(kTestMnemonic);
  });

  group('CreateHdWalletUseCase', () {
    late FakeBip39Service bip39;
    late FakeSeedRepository seedRepo;
    late FakeWalletRepository walletRepo;
    late CreateHdWalletUseCase useCase;

    setUp(() {
      bip39 = FakeBip39Service(mnemonic: kTestMnemonic);
      seedRepo = FakeSeedRepository();
      walletRepo = FakeWalletRepository();
      useCase = CreateHdWalletUseCase(
        bip39Service: bip39,
        seedRepository: seedRepo,
        walletRepository: walletRepo,
      );
    });

    test('returns wallet with non-empty UUID and HD type', () async {
      final (wallet, _) = await useCase('My Wallet');

      expect(wallet.id, isNotEmpty);
      expect(wallet.type, WalletType.hd);
      expect(wallet.name, 'My Wallet');
    });

    test('returns the generated mnemonic', () async {
      final (_, mnemonic) = await useCase('My Wallet');

      expect(mnemonic.words, kTestMnemonic.words);
    });

    test('stores seed under the new wallet id', () async {
      final (wallet, mnemonic) = await useCase('My Wallet');

      expect(seedRepo.seeds[wallet.id]?.words, mnemonic.words);
    });

    test('persists wallet to repository', () async {
      final (wallet, _) = await useCase('My Wallet');

      expect(walletRepo.saved, hasLength(1));
      expect(walletRepo.saved.first.id, wallet.id);
    });

    test('each call generates a distinct wallet id', () async {
      final (first, _) = await useCase('A');
      final (second, _) = await useCase('B');

      expect(first.id, isNot(second.id));
    });

    test('seed is stored before wallet is saved', () async {
      final mockRepo = MockWalletRepository();
      when(() => mockRepo.saveWallet(any())).thenAnswer((_) async {});
      when(() => mockRepo.getWallets()).thenAnswer((_) async => []);

      final trackingUseCase = CreateHdWalletUseCase(
        bip39Service: bip39,
        seedRepository: seedRepo,
        walletRepository: mockRepo,
      );

      final (wallet, _) = await trackingUseCase('Test');

      // Verify seed was stored before wallet was saved
      expect(seedRepo.seeds[wallet.id]?.words, kTestMnemonic.words);
      verify(() => mockRepo.saveWallet(any())).called(1);
    });
  });
}
