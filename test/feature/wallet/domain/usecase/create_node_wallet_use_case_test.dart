import 'package:bitcoin_wallet/feature/wallet/domain/usecase/create_node_wallet_use_case.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks/mock_bitcoin_core_remote_data_source.dart';
import 'mocks/mock_wallet_repository.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      Wallet(
        id: 'test',
        name: 'test',
        type: WalletType.node,
        createdAt: DateTime.utc(2024),
      ),
    );
  });

  group('CreateNodeWalletUseCase', () {
    late MockBitcoinCoreRemoteDataSource mockRemoteDataSource;
    late MockWalletRepository mockRepo;
    late CreateNodeWalletUseCase useCase;

    setUp(() {
      mockRemoteDataSource = MockBitcoinCoreRemoteDataSource();
      mockRepo = MockWalletRepository();
      when(() => mockRemoteDataSource.createWallet(any())).thenAnswer((_) async {});
      when(() => mockRepo.saveWallet(any())).thenAnswer((_) async {});
      when(() => mockRepo.getWallets()).thenAnswer((_) async => []);
      useCase = CreateNodeWalletUseCase(
        remoteDataSource: mockRemoteDataSource,
        walletRepository: mockRepo,
      );
    });

    test('returns wallet with non-empty UUID and node type', () async {
      final wallet = await useCase('Regtest Node');

      expect(wallet.id, isNotEmpty);
      expect(wallet.type, WalletType.node);
      expect(wallet.name, 'Regtest Node');
    });

    test('calls gateway.createWallet with the wallet name', () async {
      await useCase('My Node');

      verify(() => mockRemoteDataSource.createWallet('My Node')).called(1);
    });

    test('persists wallet to repository', () async {
      final wallet = await useCase('My Node');

      verify(
        () => mockRepo.saveWallet(
          any(
            that: isA<Wallet>().having((w) => w.id, 'id', wallet.id),
          ),
        ),
      ).called(1);
    });

    test('each call generates a distinct wallet id', () async {
      final first = await useCase('A');
      final second = await useCase('B');

      expect(first.id, isNot(second.id));
    });

    test('gateway is called before wallet is saved', () async {
      final wallet = await useCase('Test');

      verify(() => mockRemoteDataSource.createWallet('Test')).called(1);
      verify(
        () => mockRepo.saveWallet(
          any(
            that: isA<Wallet>().having((w) => w.id, 'id', wallet.id),
          ),
        ),
      ).called(1);
    });
  });
}
