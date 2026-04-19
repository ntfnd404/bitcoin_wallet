/// ISP interface for regtest block generation.
///
/// Used only in development / regtest environments to confirm transactions.
abstract interface class BlockGenerationDataSource {
  /// Mines [count] blocks, crediting the coinbase to [address].
  ///
  /// Returns the list of generated block hashes.
  Future<List<String>> generateToAddress(int count, String address);
}
