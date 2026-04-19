/// Mixin for entities with confirmation state.
///
/// Used by Transaction and Utxo to share mempool/confirmed/conflicted logic.
mixin Confirmable {
  /// Number of confirmations from Bitcoin Core.
  ///
  /// - 0 = mempool (unconfirmed)
  /// - >0 = confirmed in that many blocks
  /// - <0 = conflicted (orphaned)
  int get confirmations;

  /// True when transaction is in mempool (unconfirmed).
  bool get isMempool => confirmations == 0;

  /// True when transaction is confirmed (1+ blocks deep).
  bool get isConfirmed => confirmations > 0;

  /// True when transaction is conflicted (orphaned).
  bool get isConflicted => confirmations < 0;
}
