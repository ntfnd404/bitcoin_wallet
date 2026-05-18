import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/core/event_bus/events/transaction_event.dart';
import 'package:bitcoin_wallet/feature/send/application/recommend_strategy.dart';
import 'package:bitcoin_wallet/feature/send/bloc/coin_selection_mode.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_action.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_event.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_state.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';
/// Orchestrates the two-step send flow: prepare (coin selection) → confirm (broadcast).
///
/// Delegates wallet-specific logic entirely to [SendWorkflow], which captures
/// wallet identity and all configuration at construction time. The BLoC never
/// inspects [SendPreparation] subtypes — it passes [state.preparation] back
/// to [workflow.confirm] as-is.
final class SendBloc extends Bloc<SendEvent, SendState> with ActionBlocMixin<SendState, SendAction> {
  final SendWorkflow _workflow;
  final AppEventBus _eventBus;
  final String _walletId;

  SendBloc({
    required SendWorkflow workflow,
    required AppEventBus eventBus,
    required String walletId,
  }) : _workflow = workflow,
       _eventBus = eventBus,
       _walletId = walletId,
       super(const SendState()) {
    on<SendFormSubmitted>(_onFormSubmitted);
    on<SendStrategySelected>(_onStrategySelected);
    on<SendSelectionModeChanged>(_onSelectionModeChanged);
    on<SendConfirmed>(_onConfirmed);
  }

  Future<void> _onFormSubmitted(
    SendFormSubmitted event,
    Emitter<SendState> emit,
  ) async {
    emit(state.copyWith(status: SendStatus.preparing));
    try {
      final preparation = await _workflow.prepare(
        targetSat: Satoshi(event.amountSat),
        feeRateSatPerVbyte: event.feeRateSatPerVbyte,
      );

      if (preparation.strategies.isEmpty) {
        if (isClosed) return;
        emitAction(SendInsufficientFundsAction());
        emit(const SendState());

        return;
      }

      if (isClosed) return;
      emit(
        state.copyWith(
          status: SendStatus.awaitingConfirmation,
          preparation: preparation,
          strategies: preparation.strategies,
          selectedStrategy: recommendStrategy(preparation.strategies),
          selectionMode: CoinSelectionMode.auto,
          changeAddress: preparation.changeAddress,
          recipientAddress: event.recipientAddress,
          amountSat: event.amountSat,
        ),
      );
    } on TransactionException catch (e) {
      if (isClosed) return;
      emitAction(SendFailedAction(exception: e));
      emit(const SendState());
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emitAction(SendUnexpectedFailedAction());
      emit(const SendState());
    }
  }

  void _onStrategySelected(
    SendStrategySelected event,
    Emitter<SendState> emit,
  ) {
    final strategies = state.strategies;
    if (strategies == null || !strategies.containsKey(event.strategyName)) return;

    emit(state.copyWith(
      selectedStrategy: event.strategyName,
      selectionMode: CoinSelectionMode.manual,
    ));
  }

  void _onSelectionModeChanged(
    SendSelectionModeChanged event,
    Emitter<SendState> emit,
  ) {
    switch (event.mode) {
      case CoinSelectionMode.auto:
        final strategies = state.strategies;
        if (strategies == null) {
          emit(state.copyWith(selectionMode: CoinSelectionMode.auto));

          return;
        }
        emit(state.copyWith(
          selectionMode: CoinSelectionMode.auto,
          selectedStrategy: recommendStrategy(strategies),
        ));
      case CoinSelectionMode.manual:
        emit(state.copyWith(selectionMode: CoinSelectionMode.manual));
    }
  }

  Future<void> _onConfirmed(
    SendConfirmed event,
    Emitter<SendState> emit,
  ) async {
    final preparation = state.preparation;
    final strategyName = state.selectedStrategy;
    final recipientAddress = state.recipientAddress;
    final amountSat = state.amountSat;

    if (preparation == null || strategyName == null || recipientAddress == null || amountSat == null) {
      return;
    }

    emit(state.copyWith(status: SendStatus.sending));
    try {
      final txid = await _workflow.confirm(
        preparation: preparation,
        strategyName: strategyName,
        recipientAddress: recipientAddress,
        amountSat: Satoshi(amountSat),
      );

      if (isClosed) return;
      emit(state.copyWith(status: SendStatus.successful, txid: txid));
      _eventBus.emit(TransactionBroadcasted(txid: txid, walletId: _walletId));
    } on TransactionException catch (e) {
      if (isClosed) return;
      emitAction(SendFailedAction(exception: e));
      emit(state.copyWith(status: SendStatus.idle));
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emitAction(SendUnexpectedFailedAction());
      emit(state.copyWith(status: SendStatus.idle));
    }
  }
}
