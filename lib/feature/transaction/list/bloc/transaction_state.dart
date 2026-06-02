import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_filter.dart';
import 'package:transaction/transaction.dart';

final class TransactionState {
  final List<Transaction> transactions;
  final FetchStatus status;
  final TransactionFilter filter;

  List<Transaction> get filtered =>
      transactions.where(filter.matches).toList();

  const TransactionState({
    this.transactions = const [],
    this.status = FetchStatus.idle,
    this.filter = TransactionFilter.all,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    FetchStatus? status,
    TransactionFilter? filter,
  }) => TransactionState(
    transactions: transactions ?? this.transactions,
    status: status ?? this.status,
    filter: filter ?? this.filter,
  );
}
