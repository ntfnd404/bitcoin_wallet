import 'package:domain/domain.dart';

/// Returns all addresses stored for [walletId].
///
/// Delegates to the unified [AddressRepository] — no dispatch by wallet type.
final class GetAddressesUseCase {
  final AddressRepository _addressRepository;

  const GetAddressesUseCase({required AddressRepository addressRepository})
      : _addressRepository = addressRepository;

  Future<List<Address>> call(String walletId) => _addressRepository.getAddresses(walletId);
}
