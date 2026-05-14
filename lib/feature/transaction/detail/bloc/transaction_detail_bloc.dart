import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_action.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_event.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';

final class TransactionDetailBloc extends Bloc<TransactionDetailEvent, TransactionDetailState>
    with ActionBlocMixin<TransactionDetailState, TransactionDetailAction> {
  final GetTransactionDetailUseCase _getDetail;

  TransactionDetailBloc({required GetTransactionDetailUseCase getDetail})
    : _getDetail = getDetail,
      super(const TransactionDetailState()) {
    on<TransactionDetailRequested>(_onRequested);
  }

  Future<void> _onRequested(
    TransactionDetailRequested event,
    Emitter<TransactionDetailState> emit,
  ) async {
    emit(state.copyWith(status: FetchStatus.loading));
    try {
      final detail = await _getDetail(event.txid, event.walletName);
      if (isClosed) return;

      emit(state.copyWith(status: FetchStatus.loaded, detail: detail));
    } on TransactionException catch (e) {
      if (isClosed) return;
      emitAction(TransactionDetailErrorOccurred(exception: e));
      emit(state.copyWith(status: FetchStatus.initial));
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: FetchStatus.initial));
    }
  }
}
