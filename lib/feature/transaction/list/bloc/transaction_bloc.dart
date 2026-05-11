import 'dart:async';

import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/core/event_bus/events/transaction_event.dart' as bus;
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_action.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_event.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

final class TransactionBloc extends Bloc<TransactionEvent, TransactionState>
    with ActionBlocMixin<TransactionState, TransactionAction> {
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
    emit(state.copyWith(status: FetchStatus.loading));
    try {
      final transactions = await _getTransactions(event.wallet.name);
      if (isClosed) return;

      emit(
        state.copyWith(
          transactions: transactions,
          status: FetchStatus.loaded,
        ),
      );
    } on TransactionException catch (e) {
      if (isClosed) return;

      emitAction(TransactionErrorOccurred(exception: e));
      emit(state.copyWith(status: FetchStatus.error));
    } catch (e, stack) {
      Error.throwWithStackTrace(e, stack);
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
        ),
      );
    } on TransactionException catch (e) {
      if (isClosed) return;

      emitAction(TransactionErrorOccurred(exception: e));
      emit(state.copyWith(status: FetchStatus.error));
    } catch (e, stack) {
      Error.throwWithStackTrace(e, stack);
    }
  }
}
