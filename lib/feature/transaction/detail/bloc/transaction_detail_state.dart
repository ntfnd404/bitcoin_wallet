import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:transaction/transaction.dart';

final class TransactionDetailState {
  final FetchStatus status;
  final TransactionDetail? detail;

  const TransactionDetailState({
    this.status = FetchStatus.initial,
    this.detail,
  });

  TransactionDetailState copyWith({
    FetchStatus? status,
    TransactionDetail? detail,
  }) => TransactionDetailState(
    status: status ?? this.status,
    detail: detail ?? this.detail,
  );
}
