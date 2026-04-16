import 'package:domain/domain.dart';

/// [AddressRepository] backed by [AddressLocalDataSource].
///
/// Single instance serves all wallet types.
final class AddressRepositoryImpl implements AddressRepository {
  final AddressLocalDataSource _localDataSource;

  const AddressRepositoryImpl({required AddressLocalDataSource localStore}) : _localDataSource = localStore;

  @override
  Future<void> saveAddress(Address address) => _localDataSource.saveAddress(address);

  @override
  Future<List<Address>> getAddresses(String walletId) => _localDataSource.getAddresses(walletId);

  @override
  Future<int> nextAddressIndex(String walletId) => _localDataSource.nextAddressIndex(walletId);
}
