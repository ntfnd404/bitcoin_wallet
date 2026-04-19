import 'package:transaction/src/domain/value_object/hd_address_entry.dart';

/// ISP interface for reading stored HD-wallet addresses.
///
/// Defined in the `transaction` package (consumer owns the interface) and
/// implemented in the app layer using [AddressRepository].
abstract interface class HdAddressDataSource {
  /// Returns all stored addresses for [walletId] with their derivation metadata.
  Future<List<HdAddressEntry>> getAddressesForWallet(String walletId);
}
