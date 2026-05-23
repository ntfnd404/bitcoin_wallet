/// Outbound port for wallet operations on Bitcoin Core node.
abstract interface class NodeWalletGateway {
  /// Creates a named wallet inside Bitcoin Core.
  Future<void> createWallet(String walletName);
}
