import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_event.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';

/// BLoC for fetching full transaction detail on demand.
///
/// Handles [TransactionDetailRequested] to fetch [TransactionDetail]
/// for a given txid and wallet name.
final class TransactionDetailBloc
    extends Bloc<TransactionDetailEvent, TransactionDetailState> {
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
    emit(state.copyWith(status: FetchStatus.loading, clearErrorMessage: true));
    try {
      final detail = await _getDetail(event.txid, event.walletName);
      if (isClosed) return;

      emit(state.copyWith(status: FetchStatus.loaded, detail: detail));
    } catch (e) {
      if (isClosed) return;

      emit(state.copyWith(
        status: FetchStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
