import 'package:wallet/wallet.dart';

final class FakeAddressRepository implements AddressRepository {
  List<Address> addresses = const [];
  Object? throwOnGetAddresses;

  @override
  Future<List<Address>> getAddresses(String walletId) async {
    final t = throwOnGetAddresses;
    if (t != null) throw t;

    return addresses.where((a) => a.walletId == walletId).toList();
  }

  @override
  Future<void> saveAddress(Address address) async =>
      addresses = [...addresses, address];

  @override
  Future<int> nextAddressIndex(String walletId) async =>
      addresses.where((a) => a.walletId == walletId).length;
}
