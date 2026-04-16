/// Bitcoin network configuration.
///
/// Switching the active network requires changing one constant in AppConstants.
enum BitcoinNetwork {
  mainnet(
    p2pkhPrefix: 0x00,
    p2shPrefix: 0x05,
    bech32Hrp: 'bc',
    coinType: 0,
    rpcPort: 8332,
  ),
  testnet(
    p2pkhPrefix: 0x6F,
    p2shPrefix: 0xC4,
    bech32Hrp: 'tb',
    coinType: 1,
    rpcPort: 18332,
  ),
  regtest(
    p2pkhPrefix: 0x6F,
    p2shPrefix: 0xC4,
    bech32Hrp: 'bcrt',
    coinType: 1,
    rpcPort: 18443,
  )
  ;

  const BitcoinNetwork({
    required this.p2pkhPrefix,
    required this.p2shPrefix,
    required this.bech32Hrp,
    required this.coinType,
    required this.rpcPort,
  });

  /// Version byte for P2PKH (Legacy) addresses.
  final int p2pkhPrefix;

  /// Version byte for P2SH (Wrapped SegWit) addresses.
  final int p2shPrefix;

  /// Human-readable part for Bech32/Bech32m addresses.
  final String bech32Hrp;

  /// BIP44 coin_type: 0 = mainnet, 1 = testnet/regtest.
  final int coinType;

  /// Default Bitcoin Core RPC port for this network.
  final int rpcPort;
}
