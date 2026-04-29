import 'package:shared_kernel/shared_kernel.dart';

/// BIP44/49/84/86 account-level derivation path utilities.
///
/// Paths use the coin type from [BitcoinNetwork]:
///   - mainnet: coin_type = 0
///   - testnet / regtest: coin_type = 1
///
/// Append `/<index>` at derivation time.
abstract final class DerivationPaths {
  static String legacy(BitcoinNetwork n) =>
      "m/44'/${n.coinType}'/0'/0";

  static String wrappedSegwit(BitcoinNetwork n) =>
      "m/49'/${n.coinType}'/0'/0";

  static String nativeSegwit(BitcoinNetwork n) =>
      "m/84'/${n.coinType}'/0'/0";

  static String taproot(BitcoinNetwork n) =>
      "m/86'/${n.coinType}'/0'/0";
}
