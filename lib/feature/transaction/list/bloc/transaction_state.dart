import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:transaction/transaction.dart';

final class TransactionState {
  final List<Transaction> transactions;
  final FetchStatus status;
  final String? errorMessage;

  const TransactionState({
    this.transactions = const [],
    this.status = FetchStatus.initial,
    this.errorMessage,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    FetchStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) => TransactionState(
    transactions: transactions ?? this.transactions,
    status: status ?? this.status,
    errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
  );
}
