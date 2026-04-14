import 'package:domain/domain.dart';

/// In-memory address repository for unit tests.
final class FakeAddressRepository implements AddressRepository {
  final List<Address> _addresses = [];

  List<Address> get saved => List.unmodifiable(_addresses);

  @override
  Future<void> saveAddress(Address address) async => _addresses.add(address);

  @override
  Future<List<Address>> getAddresses(String walletId) async => _addresses.where((a) => a.walletId == walletId).toList();

  @override
  Future<int> nextAddressIndex(String walletId) async => _addresses.where((a) => a.walletId == walletId).length;
}
