import 'dart:convert';
import 'dart:typed_data';

import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/core/event_bus/events/transaction_domain_event.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_action.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_event.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_state.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';

/// Orchestrates the OP_RETURN transaction flow for the Node wallet.
///
/// Computes the live hex preview and byte count on every text change.
/// Delegates broadcast to [SendOpReturnUseCase] and emits result via actions.
final class OpReturnBloc extends Bloc<OpReturnEvent, OpReturnState>
    with ActionBlocMixin<OpReturnState, OpReturnAction> {
  final SendOpReturnUseCase _useCase;
  final AppEventBus _eventBus;
  final String _walletId;
  final String _walletName;

  OpReturnBloc({
    required this._useCase,
    required this._eventBus,
    required this._walletId,
    required this._walletName,
  }) : super(const OpReturnState()) {
    on<OpReturnDataChanged>(_onDataChanged);
    on<OpReturnFeeRateChanged>(_onFeeRateChanged);
    on<OpReturnBroadcastRequested>(_onBroadcastRequested);
  }

  void _onDataChanged(OpReturnDataChanged event, Emitter<OpReturnState> emit) {
    final bytes = utf8.encode(event.text);
    final byteCount = bytes.length;
    final isValid = byteCount >= 1 && byteCount <= 80;
    final hexPreview = isValid ? buildOpReturnScript(Uint8List.fromList(bytes)) : '';

    emit(
      state.copyWith(
        text: event.text,
        byteCount: byteCount,
        isValid: isValid,
        hexPreview: hexPreview,
      ),
    );
  }

  void _onFeeRateChanged(
    OpReturnFeeRateChanged event,
    Emitter<OpReturnState> emit,
  ) {
    emit(state.copyWith(feeRateSatPerVbyte: event.feeRateSatPerVbyte));
  }

  Future<void> _onBroadcastRequested(
    OpReturnBroadcastRequested event,
    Emitter<OpReturnState> emit,
  ) async {
    if (!state.isValid || state.status == OpReturnStatus.processing) return;

    emit(state.copyWith(status: OpReturnStatus.processing));
    try {
      final data = Uint8List.fromList(utf8.encode(state.text));
      final txid = await _useCase(
        walletName: _walletName,
        data: data,
        feeRateSatPerVbyte: state.feeRateSatPerVbyte,
      );

      if (isClosed) return;
      emitAction(OpReturnBroadcastedAction(txid));
      _eventBus.emit(TransactionBroadcasted(txid: txid, walletId: _walletId));
      emit(state.copyWith(status: OpReturnStatus.idle));
    } on InsufficientFundsException {
      if (isClosed) return;
      emitAction(OpReturnBroadcastFailedAction('Insufficient funds to cover the transaction fee.'));
      emit(state.copyWith(status: OpReturnStatus.idle));
    } on TransactionException catch (e) {
      if (isClosed) return;
      emitAction(OpReturnBroadcastFailedAction(e.toString()));
      emit(state.copyWith(status: OpReturnStatus.idle));
    } catch (e, stack) {
      emitAction(OpReturnUnexpectedFailedAction());
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: OpReturnStatus.idle));
    }
  }
}
