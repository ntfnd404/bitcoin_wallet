/// Outbound port for regtest block generation via Bitcoin Core.
abstract interface class BlockGenerationGateway {
  /// Mines [count] blocks, crediting the coinbase to [address].
  Future<List<String>> generateToAddress(int count, String address);
}
