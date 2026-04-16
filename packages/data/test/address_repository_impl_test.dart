import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fake_secure_storage.dart';

AddressRepositoryImpl _makeRepo() => AddressRepositoryImpl(
      localStore: AddressLocalDataSourceImpl(
        storage: FakeSecureStorage(),
        mapper: const AddressMapperImpl(),
      ),
    );

Address _address({String walletId = 'w1', int index = 0}) => Address(
      value: 'bcrt1q_$index',
      type: AddressType.nativeSegwit,
      walletId: walletId,
      index: index,
    );

void main() {
  group('AddressRepositoryImpl', () {
    test('returns empty list and index 0 initially', () async {
      final repo = _makeRepo();

      expect(await repo.getAddresses('w1'), isEmpty);
      expect(await repo.nextAddressIndex('w1'), 0);
    });

    test('persists and returns a saved address', () async {
      final repo = _makeRepo();
      final a = _address();
      await repo.saveAddress(a);
      final addresses = await repo.getAddresses('w1');

      expect(addresses, hasLength(1));
      expect(addresses.first.value, a.value);
    });

    test('nextAddressIndex increments with each saved address', () async {
      final repo = _makeRepo();

      expect(await repo.nextAddressIndex('w1'), 0);
      await repo.saveAddress(_address());
      expect(await repo.nextAddressIndex('w1'), 1);
      await repo.saveAddress(_address(index: 1));
      expect(await repo.nextAddressIndex('w1'), 2);
    });

    test('addresses are isolated per walletId', () async {
      final repo = _makeRepo();
      await repo.saveAddress(_address(walletId: 'a'));
      await repo.saveAddress(_address(walletId: 'b'));

      expect(await repo.getAddresses('a'), hasLength(1));
      expect(await repo.getAddresses('b'), hasLength(1));
      expect(await repo.nextAddressIndex('a'), 1);
      expect(await repo.nextAddressIndex('b'), 1);
    });
  });
}
