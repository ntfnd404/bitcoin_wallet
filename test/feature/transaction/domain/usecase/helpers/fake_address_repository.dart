import 'package:wallet/wallet.dart';

final class FakeAddressRepository implements AddressRepository {
  Object? throwOnGetAddresses;

  final List<Address> _addresses = [];

  List<Address> get saved => List.unmodifiable(_addresses);

  void add(Address address) => _addresses.add(address);

  @override
  Future<void> saveAddress(Address address) async => _addresses.add(address);

  @override
  Future<List<Address>> getAddresses(String walletId) async {
    final toThrow = throwOnGetAddresses;
    if (toThrow != null) throw toThrow;

    return _addresses.where((a) => a.walletId == walletId).toList();
  }

  @override
  Future<int> nextAddressIndex(String walletId) async =>
      _addresses.where((a) => a.walletId == walletId).length;
}
