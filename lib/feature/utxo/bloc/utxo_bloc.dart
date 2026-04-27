import 'dart:async';

import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/core/event_bus/events/transaction_event.dart'
    as bus;
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_event.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// BLoC for UTXO list state management.
///
/// Fetches unspent outputs from the domain layer and exposes it as state.
/// Subscribes to [AppEventBus] to auto-refresh when a transaction is
/// broadcast or a block is mined from another feature.
final class UtxoBloc extends Bloc<UtxoEvent, UtxoState> {
  final GetUtxosUseCase _getUtxos;
  late final StreamSubscription<Object> _eventSub;
  Wallet? _currentWallet;

  UtxoBloc({
    required GetUtxosUseCase getUtxos,
    required AppEventBus eventBus,
  }) : _getUtxos = getUtxos,
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

  /// Handles initial list fetch — emits loading state first.
  Future<void> _onUtxoListRequested(
    UtxoListRequested event,
    Emitter<UtxoState> emit,
  ) async {
    _currentWallet = event.wallet;
    emit(state.copyWith(status: FetchStatus.loading, clearErrorMessage: true));
    try {
      final utxos = await _getUtxos(event.wallet.name);
      if (isClosed) return;

      emit(
        state.copyWith(
          utxos: utxos,
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

  /// Handles refresh — keeps current list visible while loading.
  Future<void> _onUtxoRefreshRequested(
    UtxoRefreshRequested event,
    Emitter<UtxoState> emit,
  ) async {
    try {
      final utxos = await _getUtxos(event.wallet.name);
      if (isClosed) return;

      emit(
        state.copyWith(
          utxos: utxos,
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
