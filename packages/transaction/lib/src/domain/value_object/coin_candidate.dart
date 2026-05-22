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

  /// Address type — used for per-script fee/weight estimation (G11).
  final AddressType scriptType;

  /// Raw locking script in hex (scriptPubKey). Required for signing and
  /// script-aware validation. (Trust Wallet BitcoinUnspentTransaction pattern)
  final String scriptPubKeyHex;

  /// Raw confirmation count. `null` = unknown (HD wallet via scantxoutset
  /// does not expose per-UTXO confirmation count relative to chain tip).
  /// Node wallet sets this from [Utxo.confirmations]. (G6: null = unknown)
  final int? confirmations;

  /// True when this output is a change output from a prior send.
  /// Defaults to `false` — a change-address model is required to derive this
  /// accurately; always false until that model exists. (G11 note)
  final bool isChange;

  @override
  int get hashCode => Object.hash(txid, vout);

  const CoinCandidate({
    required this.txid,
    required this.vout,
    required this.amountSat,
    required this.age,
    this.scriptType = AddressType.nativeSegwit,
    this.scriptPubKeyHex = '',
    this.confirmations,
    this.isChange = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CoinCandidate && txid == other.txid && vout == other.vout;

  /// Returns `amountSat - inputFee` at the given fee rate and input weight.
  ///
  /// May be negative for dust UTXOs — eligibility filter must remove such
  /// candidates before they reach any selector (G5).
  int effectiveSatoshis(int feeRateSatPerVbyte, int inputVbytes) => amountSat.value - inputVbytes * feeRateSatPerVbyte;
}
