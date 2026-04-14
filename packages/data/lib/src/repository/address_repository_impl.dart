import 'package:data/src/local/address_local_store.dart';
import 'package:domain/domain.dart';

/// [AddressRepository] backed by [AddressLocalStore].
///
/// Single instance serves all wallet types.
final class AddressRepositoryImpl implements AddressRepository {
  final AddressLocalStore _localStore;

  const AddressRepositoryImpl({required AddressLocalStore localStore}) : _localStore = localStore;

  @override
  Future<void> saveAddress(Address address) => _localStore.saveAddress(address);

  @override
  Future<List<Address>> getAddresses(String walletId) => _localStore.getAddresses(walletId);

  @override
  Future<int> nextAddressIndex(String walletId) => _localStore.nextAddressIndex(walletId);
}
