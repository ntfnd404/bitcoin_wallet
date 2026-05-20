import 'dart:async';

import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/core/event_bus/events/transaction_event.dart' as bus;
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_action.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_event.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

final class UtxoBloc extends Bloc<UtxoEvent, UtxoState> with ActionBlocMixin<UtxoState, UtxoAction> {
  final UtxoRepository _utxoRepository;
  late final StreamSubscription<Object> _eventSub;
  Wallet? _currentWallet;

  UtxoBloc({
    required UtxoRepository utxoRepository,
    required AppEventBus eventBus,
  }) : _utxoRepository = utxoRepository,
       super(const UtxoState()) {
    on<UtxoListRequested>(_onUtxoListRequested);
    on<UtxoRefreshRequested>(_onUtxoRefreshRequested);

    _eventSub = eventBus.stream.listen((event) {
      if (event is! bus.TransactionEvent) return;

      final wallet = _currentWallet;
      if (wallet == null || wallet.id != event.walletId) return;

      add(UtxoRefreshRequested(wallet: wallet));
    });
  }

  @override
  Future<void> close() {
    _eventSub.cancel();

    return super.close();
  }

  Future<void> _onUtxoListRequested(
    UtxoListRequested event,
    Emitter<UtxoState> emit,
  ) async {
    _currentWallet = event.wallet;
    emit(state.copyWith(status: FetchStatus.loading));
    try {
      final utxos = await _utxoRepository.getUtxos(event.wallet.name);
      if (isClosed) return;

      emit(state.copyWith(utxos: utxos, status: FetchStatus.loaded));
    } on TransactionException catch (e) {
      if (isClosed) return;
      emitAction(UtxoErrorOccurredAction(exception: e));
      emit(state.copyWith(status: FetchStatus.initial));
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: FetchStatus.initial));
    }
  }

  Future<void> _onUtxoRefreshRequested(
    UtxoRefreshRequested event,
    Emitter<UtxoState> emit,
  ) async {
    try {
      final utxos = await _utxoRepository.getUtxos(event.wallet.name);
      if (isClosed) return;

      emit(state.copyWith(utxos: utxos, status: FetchStatus.loaded));
    } on TransactionException catch (e) {
      if (isClosed) return;
      emitAction(UtxoErrorOccurredAction(exception: e));
      emit(state.copyWith(status: FetchStatus.initial));
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: FetchStatus.initial));
    }
  }
}
