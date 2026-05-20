import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:transaction/transaction.dart';

final class TransactionState {
  final List<Transaction> transactions;
  final FetchStatus status;

  const TransactionState({
    this.transactions = const [],
    this.status = FetchStatus.idle,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    FetchStatus? status,
  }) => TransactionState(
    transactions: transactions ?? this.transactions,
    status: status ?? this.status,
  );
}
