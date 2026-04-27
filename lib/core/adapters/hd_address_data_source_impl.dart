import 'package:address/address.dart';
import 'package:transaction/transaction.dart';

/// Implements [HdAddressDataSource] by reading from [AddressRepository].
///
/// Lives in the app layer — bridges the `address` package storage to the
/// `transaction` package's ISP interface.
final class HdAddressDataSourceImpl implements HdAddressDataSource {
  final AddressRepository _repository;

  const HdAddressDataSourceImpl({required AddressRepository repository}) : _repository = repository;

  @override
  Future<List<Address>> getAddressesForWallet(String walletId) async {
    final addresses = await _repository.getAddresses(walletId);

    return addresses;
  }
}
