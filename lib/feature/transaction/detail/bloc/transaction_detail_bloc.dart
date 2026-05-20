import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/decoded_transaction_input.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/decoded_transaction_output.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_action.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_event.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';

final class TransactionDetailBloc extends Bloc<TransactionDetailEvent, TransactionDetailState>
    with ActionBlocMixin<TransactionDetailState, TransactionDetailAction> {
  final TransactionRepository _repository;

  TransactionDetailBloc({required TransactionRepository repository})
    : _repository = repository,
      super(const TransactionDetailState()) {
    on<TransactionDetailRequested>(_onRequested);
  }

  Future<void> _onRequested(
    TransactionDetailRequested event,
    Emitter<TransactionDetailState> emit,
  ) async {
    emit(state.copyWith(status: FetchStatus.processing));
    try {
      final detail = await _repository.getTransactionDetail(event.txid, event.walletName);
      if (isClosed) return;

      const classifier = DefaultScriptClassifier();
      const decoder = DefaultScriptDecoder();

      final decodedOutputs = detail.outputs.map((o) => DecodedTransactionOutput(
        output: o,
        scriptTypeLabel: classifier.classify(o.scriptPubKeyHex).label,
        asm: decoder.decode(o.scriptPubKeyHex),
      )).toList();

      final decodedInputs = detail.inputs.map((i) => DecodedTransactionInput(
        input: i,
        asm: i.isCoinbase
            ? ''
            : i.scriptSigHex.isNotEmpty
                ? decoder.decode(i.scriptSigHex)
                : decoder.decodeWitness(i.witness),
      )).toList();

      emit(state.copyWith(
        status: FetchStatus.idle,
        detail: detail,
        decodedOutputs: decodedOutputs,
        decodedInputs: decodedInputs,
      ));
    } on TransactionException catch (e) {
      if (isClosed) return;
      emitAction(TransactionDetailErrorOccurredAction(exception: e));
      emit(state.copyWith(status: FetchStatus.idle));
    } catch (e, stack) {
      emitAction(TransactionDetailUnexpectedFailedAction());
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: FetchStatus.idle));
    }
  }
}
