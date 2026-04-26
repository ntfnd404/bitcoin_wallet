import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_event.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';

/// BLoC for transaction list state management.
///
/// Fetches transaction history from the domain layer and exposes it as state.
final class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactionsUseCase _getTransactions;

  TransactionBloc({required GetTransactionsUseCase getTransactions})
    : _getTransactions = getTransactions,
      super(const TransactionState()) {
    on<TransactionListRequested>(_onTransactionListRequested);
    on<TransactionRefreshRequested>(_onTransactionRefreshRequested);
  }

  Future<void> _onTransactionListRequested(
    TransactionListRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(state.copyWith(status: FetchStatus.loading, clearErrorMessage: true));
    try {
      final transactions = await _getTransactions(event.wallet.name);
      if (isClosed) return;

      emit(
        state.copyWith(
          transactions: transactions,
          status: FetchStatus.loaded,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          status: FetchStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onTransactionRefreshRequested(
    TransactionRefreshRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final transactions = await _getTransactions(event.wallet.name);
      if (isClosed) return;

      emit(
        state.copyWith(
          transactions: transactions,
          status: FetchStatus.loaded,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          status: FetchStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
