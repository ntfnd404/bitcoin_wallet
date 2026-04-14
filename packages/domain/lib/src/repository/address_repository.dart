import 'package:domain/src/entity/address.dart';

/// Unified storage contract for addresses across all wallet types.
///
/// Pure CRUD — no derivation or RPC logic. The [Address.walletId] field
/// associates each address with its owning wallet.
abstract interface class AddressRepository {
  /// Persists [address]. Overwrites if the same value + walletId exists.
  Future<void> saveAddress(Address address);

  /// Returns all stored addresses for [walletId].
  Future<List<Address>> getAddresses(String walletId);

  /// Returns the next derivation index for [walletId].
  ///
  /// Equals the count of already-stored addresses for that wallet.
  /// Used by both Node (for sequential tracking) and HD (for BIP32 index).
  Future<int> nextAddressIndex(String walletId);
}
