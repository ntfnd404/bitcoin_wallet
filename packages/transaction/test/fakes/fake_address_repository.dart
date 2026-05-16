import 'package:wallet/wallet.dart';

final class FakeAddressRepository implements AddressRepository {
  Object? throwOnGetAddresses;

  List<Address> addresses = [];

  List<Address> get saved => List.unmodifiable(addresses);

  void add(Address address) => addresses.add(address);

  @override
  Future<List<Address>> getAddresses(String walletId) async {
    final t = throwOnGetAddresses;
    if (t != null) throw t;

    return addresses.where((a) => a.walletId == walletId).toList();
  }

  @override
  Future<void> saveAddress(Address address) async => addresses.add(address);

  @override
  Future<int> nextAddressIndex(String walletId) async =>
      addresses.where((a) => a.walletId == walletId).length;
}
