import 'package:domain/src/entity/address_type.dart';

/// Port for communicating with a Bitcoin Core full node via JSON-RPC.
///
/// Lives in domain so use cases can depend on it directly without
/// knowing about the HTTP/RPC transport layer.
/// The adapter ([BitcoinCoreGatewayImpl]) lives in the data package.
abstract interface class BitcoinCoreGateway {
  /// Creates a named wallet inside Bitcoin Core.
  Future<void> createWallet(String walletName);

  /// Asks Bitcoin Core to derive the next address of [type] for [walletName].
  ///
  /// Returns the raw address string.
  Future<String> generateAddress(String walletName, AddressType type);
}
