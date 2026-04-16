import 'package:domain/domain.dart';

abstract interface class AddressLocalDataSource {
  Future<List<Address>> getAddresses(String walletId);

  Future<void> saveAddress(Address address);

  Future<int> nextAddressIndex(String walletId);
}
