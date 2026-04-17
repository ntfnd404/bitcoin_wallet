import 'package:shared_kernel/shared_kernel.dart';

/// An unspent transaction output (UTXO) as reported by Bitcoin Core.
///
/// Amounts are in satoshis (1 BTC = 100,000,000 satoshis).
final class Utxo {
  /// Transaction ID that created this output, hex string.
  final String txid;

  /// Output index within the transaction.
  final int vout;

  /// Amount in satoshis.
  final int amountSat;

  /// Number of confirmations. 0 = mempool, >0 = confirmed.
  final int confirmations;

  /// Bitcoin address that received this output.
  final String address;

  /// Raw scriptPubKey in hex.
  final String scriptPubKey;

  /// Address type derived from scriptPubKey.
  final AddressType type;

  /// True if the UTXO is spendable by this wallet.
  final bool spendable;

  /// True if the UTXO is in the mempool (not yet confirmed).
  bool get isMempool => confirmations == 0;

  const Utxo({
    required this.txid,
    required this.vout,
    required this.amountSat,
    required this.confirmations,
    required this.address,
    required this.scriptPubKey,
    required this.type,
    required this.spendable,
  });
}
