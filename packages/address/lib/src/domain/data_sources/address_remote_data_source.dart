import 'package:shared_kernel/shared_kernel.dart';

/// Contract for address generation on Bitcoin Core node.
///
/// ISP split from the monolithic BitcoinCoreRemoteDataSource.
/// Implementation lives in the bitcoin_node adapter package.
abstract interface class AddressRemoteDataSource {
  /// Asks Bitcoin Core to derive the next address of [type] for [walletName].
  ///
  /// Returns the raw address string.
  Future<String> generateAddress(String walletName, AddressType type);
}
