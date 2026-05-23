import 'dart:async';

import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/core/event_bus/events/transaction_domain_event.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_action.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_event.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

final class TransactionBloc extends Bloc<TransactionEvent, TransactionState>
    with ActionBlocMixin<TransactionState, TransactionAction> {
  final TransactionRepository _repository;
  late final StreamSubscription<Object> _eventSub;
  Wallet? _currentWallet;

  TransactionBloc({
    required this._repository,
    required AppEventBus eventBus,
  }) : super(const TransactionState()) {
    on<TransactionListRequested>(_onTransactionListRequested);
    on<TransactionRefreshRequested>(_onTransactionRefreshRequested);

    _eventSub = eventBus.on<TransactionDomainEvent>().listen((event) {
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
    emit(state.copyWith(status: FetchStatus.processing));
    try {
      final transactions = await _repository.getTransactions(event.wallet.name);
      if (isClosed) return;

      emit(state.copyWith(transactions: transactions, status: FetchStatus.idle));
    } on TransactionException catch (e) {
      if (isClosed) return;
      emitAction(TransactionErrorOccurredAction(exception: e));
      emit(state.copyWith(status: FetchStatus.idle));
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: FetchStatus.idle));
    }
  }

  Future<void> _onTransactionRefreshRequested(
    TransactionRefreshRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final transactions = await _repository.getTransactions(event.wallet.name);
      if (isClosed) return;

      emit(state.copyWith(transactions: transactions, status: FetchStatus.idle));
    } on TransactionException catch (e) {
      if (isClosed) return;
      emitAction(TransactionErrorOccurredAction(exception: e));
      emit(state.copyWith(status: FetchStatus.idle));
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: FetchStatus.idle));
    }
  }
}
