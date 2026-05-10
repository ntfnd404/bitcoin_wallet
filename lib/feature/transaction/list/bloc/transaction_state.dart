import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:transaction/transaction.dart';

final class TransactionState {
  final List<Transaction> transactions;
  final FetchStatus status;
  final Exception? exception;

  const TransactionState({
    this.transactions = const [],
    this.status = FetchStatus.initial,
    this.exception,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    FetchStatus? status,
    Exception? exception,
    bool clearException = false,
  }) => TransactionState(
    transactions: transactions ?? this.transactions,
    status: status ?? this.status,
    exception: clearException ? null : (exception ?? this.exception),
  );
}
