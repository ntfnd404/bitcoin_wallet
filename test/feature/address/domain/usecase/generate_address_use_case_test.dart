import 'package:address/address.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/wallet.dart';

import 'fakes/test_fixtures.dart';
import 'mocks/mock_address_generation_strategy.dart';

HdWallet _hdWallet() => HdWallet(
  id: 'w1',
  name: 'Test',
  createdAt: DateTime.utc(2024),
);

NodeWallet _nodeWallet() => NodeWallet(
  id: 'w2',
  name: 'Test Node',
  createdAt: DateTime.utc(2024),
);

void main() {
  setUpAll(() {
    registerFallbackValue(AddressType.nativeSegwit);
    registerFallbackValue(_hdWallet());
    registerFallbackValue(testAddress());
  });

  group('GenerateAddressUseCase', () {
    late MockAddressGenerationStrategy hdStrategy;
    late MockAddressGenerationStrategy nodeStrategy;
    late GenerateAddressUseCase useCase;

    setUp(() {
      hdStrategy = MockAddressGenerationStrategy();
      nodeStrategy = MockAddressGenerationStrategy();

      // HD strategy supports hd wallets
      when(() => hdStrategy.supports(any(that: isA<HdWallet>()))).thenReturn(true);
      when(() => hdStrategy.supports(any(that: isA<NodeWallet>()))).thenReturn(false);
      when(() => hdStrategy.generate(any(), any())).thenAnswer((_) async => testAddress());

      // Node strategy supports node wallets
      when(() => nodeStrategy.supports(any(that: isA<HdWallet>()))).thenReturn(false);
      when(() => nodeStrategy.supports(any(that: isA<NodeWallet>()))).thenReturn(true);
      when(() => nodeStrategy.generate(any(), any())).thenAnswer((_) async => testAddress(value: 'bcrt1qnode'));

      useCase = GenerateAddressUseCase(strategies: [hdStrategy, nodeStrategy]);
    });

    test('delegates to HD strategy for HD wallet', () async {
      final wallet = _hdWallet();
      final address = await useCase(wallet, AddressType.nativeSegwit);

      expect(address.value, testAddress().value);
      verify(() => hdStrategy.generate(wallet, AddressType.nativeSegwit)).called(1);
      verifyNever(() => nodeStrategy.generate(any(), any()));
    });

    test('delegates to node strategy for node wallet', () async {
      final wallet = _nodeWallet();
      final address = await useCase(wallet, AddressType.nativeSegwit);

      expect(address.value, 'bcrt1qnode');
      verify(() => nodeStrategy.generate(wallet, AddressType.nativeSegwit)).called(1);
      verifyNever(() => hdStrategy.generate(any(), any()));
    });

    test('throws StateError when no strategy supports the wallet type', () {
      const noStrategyUseCase = GenerateAddressUseCase(strategies: []);
      final wallet = _hdWallet();

      expect(
        () => noStrategyUseCase(wallet, AddressType.nativeSegwit),
        throwsA(isA<StateError>()),
      );
    });

    test('passes address type to the chosen strategy', () async {
      const expectedType = AddressType.taproot;
      when(() => hdStrategy.supports(any(that: isA<HdWallet>()))).thenReturn(true);
      when(() => hdStrategy.generate(any(), expectedType)).thenAnswer((_) async => testAddress(type: expectedType));

      final wallet = _hdWallet();
      final address = await useCase(wallet, expectedType);

      verify(() => hdStrategy.generate(wallet, expectedType)).called(1);
      expect(address.type, expectedType);
    });

    test('uses first matching strategy when multiple support the type', () async {
      final second = MockAddressGenerationStrategy();
      when(() => hdStrategy.supports(any(that: isA<HdWallet>()))).thenReturn(true);
      when(() => hdStrategy.generate(any(), any())).thenAnswer((_) async => testAddress());
      when(() => second.supports(any(that: isA<HdWallet>()))).thenReturn(true);
      when(() => second.generate(any(), any())).thenAnswer((_) async => testAddress(value: 'bcrt1qsecond'));

      final multiUseCase = GenerateAddressUseCase(strategies: [hdStrategy, second]);

      await multiUseCase(_hdWallet(), AddressType.nativeSegwit);

      verify(() => hdStrategy.generate(any(), any())).called(1);
      verifyNever(() => second.generate(any(), any()));
    });
  });
}
