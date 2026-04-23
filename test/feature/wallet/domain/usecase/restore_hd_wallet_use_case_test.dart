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
      HdWallet(
        id: 'test',
        name: 'test',
        createdAt: DateTime.utc(2024),
      ),
    );
  });

  group('RestoreHdWalletUseCase', () {
    late FakeBip39Service bip39;
    late FakeSeedRepository seedRepo;
    late FakeWalletRepository walletRepo;
    late RestoreHdWalletUseCase useCase;

    setUp(() {
      bip39 = FakeBip39Service(mnemonic: kTestMnemonic);
      seedRepo = FakeSeedRepository();
      walletRepo = FakeWalletRepository();
      useCase = RestoreHdWalletUseCase(
        bip39Service: bip39,
        seedRepository: seedRepo,
        hdWalletRepository: walletRepo,
      );
    });

    test('returns wallet with HD type and provided name', () async {
      final wallet = await useCase('Restored', kTestMnemonic);

      expect(wallet.id, isNotEmpty);
      expect(wallet, isA<HdWallet>());
      expect(wallet.name, 'Restored');
    });

    test('stores seed under the new wallet id', () async {
      final wallet = await useCase('Restored', kTestMnemonic);

      expect(seedRepo.seeds[wallet.id]?.words, kTestMnemonic.words);
    });

    test('persists wallet to repository', () async {
      final wallet = await useCase('Restored', kTestMnemonic);

      expect(walletRepo.saved, hasLength(1));
      expect(walletRepo.saved.first.id, wallet.id);
    });

    test('throws ArgumentError for invalid mnemonic', () async {
      bip39.isValid = false;

      expect(
        () => useCase('Bad', kTestMnemonic),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('does not store seed when mnemonic is invalid', () async {
      bip39.isValid = false;

      await expectLater(
        () => useCase('Bad', kTestMnemonic),
        throwsA(isA<ArgumentError>()),
      );

      expect(seedRepo.seeds, isEmpty);
    });

    test('each call generates a distinct wallet id', () async {
      final first = await useCase('A', kTestMnemonic);
      final second = await useCase('B', kTestMnemonic);

      expect(first.id, isNot(second.id));
    });

    test('seed is stored before wallet is saved', () async {
      final mockRepo = MockWalletRepository();
      when(() => mockRepo.saveWallet(any())).thenAnswer((_) async {});
      when(() => mockRepo.getWallets()).thenAnswer((_) async => []);

      final trackingUseCase = RestoreHdWalletUseCase(
        bip39Service: bip39,
        seedRepository: seedRepo,
        hdWalletRepository: mockRepo,
      );

      final wallet = await trackingUseCase('Test', kTestMnemonic);

      expect(seedRepo.seeds[wallet.id]?.words, kTestMnemonic.words);
      verify(() => mockRepo.saveWallet(any())).called(1);
    });
  });
}
