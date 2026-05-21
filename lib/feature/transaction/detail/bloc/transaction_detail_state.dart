import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/decoded_transaction_input.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/decoded_transaction_output.dart';
import 'package:transaction/transaction.dart';

final class TransactionDetailState {
  final FetchStatus status;
  final TransactionDetail? detail;
  final List<DecodedTransactionOutput> decodedOutputs;
  final List<DecodedTransactionInput> decodedInputs;

  const TransactionDetailState({
    this.status = FetchStatus.idle,
    this.detail,
    this.decodedOutputs = const [],
    this.decodedInputs = const [],
  });

  TransactionDetailState copyWith({
    FetchStatus? status,
    TransactionDetail? detail,
    List<DecodedTransactionOutput>? decodedOutputs,
    List<DecodedTransactionInput>? decodedInputs,
  }) => TransactionDetailState(
    status: status ?? this.status,
    detail: detail ?? this.detail,
    decodedOutputs: decodedOutputs ?? this.decodedOutputs,
    decodedInputs: decodedInputs ?? this.decodedInputs,
  );
}
