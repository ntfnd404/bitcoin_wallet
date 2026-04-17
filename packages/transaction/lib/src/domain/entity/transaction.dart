import 'package:transaction/src/domain/entity/transaction_direction.dart';

/// A wallet transaction as reported by Bitcoin Core.
///
/// Amounts are in satoshis (1 BTC = 100,000,000 satoshis).
/// [confirmations] == 0 means the transaction is in the mempool (unconfirmed).
/// [confirmations] < 0 means the transaction conflicts with another mempool tx.
final class Transaction {
  /// Transaction ID (txid), hex string.
  final String txid;

  /// Whether this is an incoming or outgoing transaction.
  final TransactionDirection direction;

  /// Net amount transferred in satoshis.
  /// Positive for incoming, negative for outgoing (including fee).
  final int amountSat;

  /// Fee paid in satoshis. Null if not available (e.g., for received txs).
  final int? feeSat;

  /// Number of confirmations. 0 = mempool, >0 = confirmed, <0 = conflicted.
  final int confirmations;

  /// Time of the transaction (block time if confirmed, receive time otherwise).
  final DateTime timestamp;

  /// True if the transaction is in the mempool (not yet confirmed).
  bool get isMempool => confirmations == 0;

  /// True if the transaction is confirmed (at least 1 confirmation).
  bool get isConfirmed => confirmations > 0;

  /// True if the transaction conflicts with another mempool transaction.
  bool get isConflicted => confirmations < 0;

  const Transaction({
    required this.txid,
    required this.direction,
    required this.amountSat,
    required this.confirmations,
    required this.timestamp,
    this.feeSat,
  });
}
