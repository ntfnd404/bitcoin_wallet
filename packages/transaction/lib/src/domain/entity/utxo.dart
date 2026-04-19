import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/entity/confirmable.dart';

/// An unspent transaction output (UTXO) as reported by Bitcoin Core.
final class Utxo with Confirmable {
  /// Transaction ID that created this output, hex string.
  final String txid;

  /// Output index within the transaction.
  final int vout;

  /// Amount in satoshis.
  final Satoshi amountSat;

  /// Number of confirmations. 0 = mempool, >0 = confirmed.
  @override
  final int confirmations;

  /// Bitcoin address that received this output.
  /// May be null for OP_RETURN, P2PK, and other unaddressable outputs.
  final String? address;

  /// Raw scriptPubKey in hex.
  final String scriptPubKey;

  /// Address type derived from scriptPubKey.
  final AddressType type;

  /// True if the UTXO is spendable by this wallet.
  final bool spendable;

  /// BIP derivation path extracted from the Bitcoin Core descriptor.
  ///
  /// Format: `m/purpose'/coin_type'/account'/change/index`
  /// (e.g. `m/84'/1'/0'/0/5`). Null if the descriptor is unavailable.
  final String? derivationPath;

  @override
  int get hashCode => Object.hash(txid, vout);

  const Utxo({
    required this.txid,
    required this.vout,
    required this.amountSat,
    required this.confirmations,
    required this.address,
    required this.scriptPubKey,
    required this.type,
    required this.spendable,
    this.derivationPath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Utxo && txid == other.txid && vout == other.vout;
}
