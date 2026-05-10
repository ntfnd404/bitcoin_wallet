import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:transaction/transaction.dart';

final class TransactionDetailState {
  final FetchStatus status;
  final TransactionDetail? detail;
  final Exception? exception;

  const TransactionDetailState({
    this.status = FetchStatus.initial,
    this.detail,
    this.exception,
  });

  TransactionDetailState copyWith({
    FetchStatus? status,
    TransactionDetail? detail,
    Exception? exception,
    bool clearException = false,
  }) => TransactionDetailState(
    status: status ?? this.status,
    detail: detail ?? this.detail,
    exception: clearException ? null : (exception ?? this.exception),
  );
}
