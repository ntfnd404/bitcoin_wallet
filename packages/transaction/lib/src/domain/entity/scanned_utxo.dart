import 'package:shared_kernel/shared_kernel.dart';

/// A UTXO found by `scantxoutset` — not tied to any wallet.
///
/// Used when scanning for UTXOs at specific addresses (e.g. for HD wallets
/// that are not imported into any Bitcoin Core wallet).
final class ScannedUtxo {
  final String txid;
  final int vout;
  final Satoshi amountSat;
  final String scriptPubKeyHex;

  /// Block height at which this UTXO was created (0 = mempool).
  final int height;

  /// The address that owns this output, parsed from the `scantxoutset` descriptor.
  /// Null if the descriptor could not be parsed.
  final String? address;

  const ScannedUtxo({
    required this.txid,
    required this.vout,
    required this.amountSat,
    required this.scriptPubKeyHex,
    required this.height,
    this.address,
  });
}
