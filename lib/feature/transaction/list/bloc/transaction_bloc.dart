import 'dart:async';

import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/core/event_bus/events/transaction_event.dart'
    as bus;
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_event.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// BLoC for transaction list state management.
///
/// Fetches transaction history from the domain layer and exposes it as state.
/// Subscribes to [AppEventBus] to auto-refresh when a transaction is
/// broadcast or a block is mined from another feature.
final class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactionsUseCase _getTransactions;
  late final StreamSubscription<Object> _eventSub;
  Wallet? _currentWallet;

  TransactionBloc({
    required GetTransactionsUseCase getTransactions,
    required AppEventBus eventBus,
  }) : _getTransactions = getTransactions,
       super(const TransactionState()) {
    on<TransactionListRequested>(_onTransactionListRequested);
    on<TransactionRefreshRequested>(_onTransactionRefreshRequested);

    _eventSub = eventBus.stream.listen((event) {
      if (event is! bus.TransactionEvent) return;
      final wallet = _currentWallet;
      if (wallet == null || wallet.id != event.walletId) return;

      add(TransactionRefreshRequested(wallet: wallet));
    });
  }

  @override
  Future<void> close() {
    _eventSub.cancel();

    return super.close();
  }

  Future<void> _onTransactionListRequested(
    TransactionListRequested event,
    Emitter<TransactionState> emit,
  ) async {
    _currentWallet = event.wallet;
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
