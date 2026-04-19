sealed class TransactionDetailEvent {
  const TransactionDetailEvent();
}

final class TransactionDetailRequested extends TransactionDetailEvent {
  final String txid;
  final String walletName;

  const TransactionDetailRequested({
    required this.txid,
    required this.walletName,
  });
}
