import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/entity/confirmable.dart';
import 'package:transaction/src/domain/entity/transaction_direction.dart';

/// A wallet transaction as reported by Bitcoin Core.
///
/// [confirmations] == 0 means the transaction is in the mempool (unconfirmed).
/// [confirmations] < 0 means the transaction conflicts with another mempool tx.
final class Transaction with Confirmable {
  /// Transaction ID (txid), hex string.
  final String txid;

  /// Whether this is an incoming or outgoing transaction.
  final TransactionDirection direction;

  /// Net amount transferred in satoshis.
  /// Positive for incoming, negative for outgoing (including fee).
  final Satoshi amountSat;

  /// Fee paid in satoshis. Null if not available (e.g., for received txs).
  final Satoshi? feeSat;

  /// Number of confirmations. 0 = mempool, >0 = confirmed, <0 = conflicted.
  @override
  final int confirmations;

  /// Time of the transaction (block time if confirmed, receive time otherwise).
  final DateTime timestamp;

  @override
  int get hashCode => txid.hashCode;

  const Transaction({
    required this.txid,
    required this.direction,
    required this.amountSat,
    required this.confirmations,
    required this.timestamp,
    this.feeSat,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Transaction && txid == other.txid;
}
