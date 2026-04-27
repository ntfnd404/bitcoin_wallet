import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet/wallet.dart';

import '../mocks/mock_wallet_repository.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      NodeWallet(
        id: 'test',
        name: 'test',
        createdAt: DateTime.utc(2024),
      ),
    );
  });

  group('CreateNodeWalletUseCase', () {
    late MockWalletRepository mockRepo;
    late CreateNodeWalletUseCase useCase;

    NodeWallet stubWallet(String name) => NodeWallet(
      id: 'stub-id',
      name: name,
      createdAt: DateTime.utc(2024),
    );

    setUp(() {
      mockRepo = MockWalletRepository();
      when(
        () => mockRepo.createNodeWallet(any()),
      ).thenAnswer((inv) async => stubWallet(inv.positionalArguments[0] as String));
      when(() => mockRepo.getWallets()).thenAnswer((_) async => []);
      useCase = CreateNodeWalletUseCase(nodeWalletRepository: mockRepo);
    });

    test('returns NodeWallet with the given name', () async {
      final wallet = await useCase('Regtest Node');

      expect(wallet, isA<NodeWallet>());
      expect(wallet.name, 'Regtest Node');
    });

    test('delegates to repository.createNodeWallet', () async {
      await useCase('My Node');

      verify(() => mockRepo.createNodeWallet('My Node')).called(1);
    });

    test('each call invokes repository once per name', () async {
      await useCase('A');
      await useCase('B');

      verify(() => mockRepo.createNodeWallet('A')).called(1);
      verify(() => mockRepo.createNodeWallet('B')).called(1);
    });
  });
}
