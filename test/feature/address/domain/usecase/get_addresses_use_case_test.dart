import 'package:bitcoin_wallet/feature/address/domain/usecase/get_addresses_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_address_repository.dart';
import 'fakes/test_fixtures.dart';

void main() {
  group('GetAddressesUseCase', () {
    late FakeAddressRepository addressRepo;
    late GetAddressesUseCase useCase;

    setUp(() {
      addressRepo = FakeAddressRepository();
      useCase = GetAddressesUseCase(addressRepository: addressRepo);
    });

    test('returns empty list when wallet has no addresses', () async {
      final addresses = await useCase('w1');

      expect(addresses, isEmpty);
    });

    test('returns only addresses belonging to the requested wallet', () async {
      final a1 = testAddress();
      final a2 = testAddress(value: 'bcrt1qtest2', index: 1);
      final other = testAddress(value: 'bcrt1qother', walletId: 'w2');
      await addressRepo.saveAddress(a1);
      await addressRepo.saveAddress(a2);
      await addressRepo.saveAddress(other);

      final addresses = await useCase('w1');

      expect(addresses, hasLength(2));
      expect(addresses.every((a) => a.walletId == 'w1'), isTrue);
    });

    test('returns addresses in insertion order', () async {
      for (var i = 0; i < 3; i++) {
        await addressRepo.saveAddress(testAddress(value: 'bcrt1q$i', index: i));
      }

      final addresses = await useCase('w1');
      final indices = addresses.map((a) => a.index).toList();

      expect(indices, [0, 1, 2]);
    });
  });
}
