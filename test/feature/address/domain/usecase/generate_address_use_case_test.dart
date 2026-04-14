import 'package:bitcoin_wallet/feature/address/domain/usecase/generate_address_use_case.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'fakes/test_fixtures.dart';
import 'mocks/mock_address_generation_strategy.dart';

Wallet _wallet({WalletType type = WalletType.hd}) => Wallet(
  id: 'w1',
  name: 'Test',
  type: type,
  createdAt: DateTime.utc(2024),
);

void main() {
  setUpAll(() {
    registerFallbackValue(WalletType.hd);
    registerFallbackValue(AddressType.nativeSegwit);
    registerFallbackValue(_wallet());
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
      when(() => hdStrategy.supports(WalletType.hd)).thenReturn(true);
      when(() => hdStrategy.supports(WalletType.node)).thenReturn(false);
      when(() => hdStrategy.generate(any(), any())).thenAnswer((_) async => testAddress());

      // Node strategy supports node wallets
      when(() => nodeStrategy.supports(WalletType.hd)).thenReturn(false);
      when(() => nodeStrategy.supports(WalletType.node)).thenReturn(true);
      when(() => nodeStrategy.generate(any(), any())).thenAnswer((_) async => testAddress(value: 'bcrt1qnode'));

      useCase = GenerateAddressUseCase(strategies: [hdStrategy, nodeStrategy]);
    });

    test('delegates to HD strategy for HD wallet', () async {
      final wallet = _wallet();
      final address = await useCase(wallet, AddressType.nativeSegwit);

      expect(address.value, testAddress().value);
      verify(() => hdStrategy.generate(wallet, AddressType.nativeSegwit)).called(1);
      verifyNever(() => nodeStrategy.generate(any(), any()));
    });

    test('delegates to node strategy for node wallet', () async {
      final wallet = _wallet(type: WalletType.node);
      final address = await useCase(wallet, AddressType.nativeSegwit);

      expect(address.value, 'bcrt1qnode');
      verify(() => nodeStrategy.generate(wallet, AddressType.nativeSegwit)).called(1);
      verifyNever(() => hdStrategy.generate(any(), any()));
    });

    test('throws StateError when no strategy supports the wallet type', () {
      const noStrategyUseCase = GenerateAddressUseCase(strategies: []);
      final wallet = _wallet();

      expect(
        () => noStrategyUseCase(wallet, AddressType.nativeSegwit),
        throwsA(isA<StateError>()),
      );
    });

    test('passes address type to the chosen strategy', () async {
      const expectedType = AddressType.taproot;
      when(() => hdStrategy.supports(WalletType.hd)).thenReturn(true);
      when(() => hdStrategy.generate(any(), expectedType)).thenAnswer((_) async => testAddress(type: expectedType));

      final wallet = _wallet();
      final address = await useCase(wallet, expectedType);

      verify(() => hdStrategy.generate(wallet, expectedType)).called(1);
      expect(address.type, expectedType);
    });

    test('uses first matching strategy when multiple support the type', () async {
      final second = MockAddressGenerationStrategy();
      when(() => hdStrategy.supports(WalletType.hd)).thenReturn(true);
      when(() => hdStrategy.generate(any(), any())).thenAnswer((_) async => testAddress());
      when(() => second.supports(WalletType.hd)).thenReturn(true);
      when(() => second.generate(any(), any())).thenAnswer((_) async => testAddress(value: 'bcrt1qsecond'));

      final multiUseCase = GenerateAddressUseCase(strategies: [hdStrategy, second]);

      await multiUseCase(_wallet(), AddressType.nativeSegwit);

      verify(() => hdStrategy.generate(any(), any())).called(1);
      verifyNever(() => second.generate(any(), any()));
    });
  });
}
