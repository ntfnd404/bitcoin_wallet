import 'package:address/src/domain/data_sources/address_local_data_source.dart';
import 'package:address/src/domain/entity/address.dart';
import 'package:address/src/domain/repository/address_repository.dart';

/// [AddressRepository] backed by [AddressLocalDataSource].
///
/// Single instance serves all wallet types.
final class AddressRepositoryImpl implements AddressRepository {
  final AddressLocalDataSource _localDataSource;

  const AddressRepositoryImpl({required AddressLocalDataSource localDataSource}) : _localDataSource = localDataSource;

  @override
  Future<void> saveAddress(Address address) => _localDataSource.saveAddress(address);

  @override
  Future<List<Address>> getAddresses(String walletId) => _localDataSource.getAddresses(walletId);

  @override
  Future<int> nextAddressIndex(String walletId) => _localDataSource.nextAddressIndex(walletId);
}
