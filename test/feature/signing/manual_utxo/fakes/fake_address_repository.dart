import 'package:wallet/wallet.dart';

final class FakeAddressRepository implements AddressRepository {
  final List<Address> addresses;

  FakeAddressRepository(this.addresses);

  @override
  Future<List<Address>> getAddresses(String walletId) async => addresses;

  @override
  Future<void> saveAddress(Address address) async {}

  @override
  Future<int> nextAddressIndex(String walletId) async => addresses.length;
}
