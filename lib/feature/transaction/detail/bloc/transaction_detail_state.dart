import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:transaction/transaction.dart';

final class TransactionDetailState {
  final FetchStatus status;
  final TransactionDetail? detail;
  final String? errorMessage;

  const TransactionDetailState({
    this.status = FetchStatus.initial,
    this.detail,
    this.errorMessage,
  });

  TransactionDetailState copyWith({
    FetchStatus? status,
    TransactionDetail? detail,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) =>
      TransactionDetailState(
        status: status ?? this.status,
        detail: detail ?? this.detail,
        errorMessage:
            clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      );
}
