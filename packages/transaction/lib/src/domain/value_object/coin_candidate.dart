import 'package:shared_kernel/shared_kernel.dart';

/// Wallet-agnostic descriptor of an unspent output suitable for coin selection.
///
/// Both Node-wallet [Utxo]s and HD-wallet [ScannedUtxo]s map to this type before
/// being passed to any [CoinSelector] strategy.
///
/// [age] is normalised so that **higher = older**:
/// - Node wallet: `age = confirmations`
/// - HD wallet: `age = rank` assigned by [PrepareHdSendUseCase] where the
///   oldest UTXO (lowest block height) receives the highest rank.
final class CoinCandidate {
  final String txid;
  final int vout;
  final Satoshi amountSat;

  /// Normalised age value. Higher means the coin has been unspent longer.
  final int age;

  @override
  int get hashCode => Object.hash(txid, vout);

  const CoinCandidate({
    required this.txid,
    required this.vout,
    required this.amountSat,
    required this.age,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoinCandidate && txid == other.txid && vout == other.vout;
}
