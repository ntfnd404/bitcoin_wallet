/// Contract for wallet operations on Bitcoin Core node.
///
/// ISP split from the monolithic BitcoinCoreRemoteDataSource.
/// Implementation lives in the bitcoin_node adapter package.
abstract interface class WalletRemoteDataSource {
  /// Creates a named wallet inside Bitcoin Core.
  Future<void> createWallet(String walletName);
}
