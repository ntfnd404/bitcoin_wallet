import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_event.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';

/// BLoC for UTXO list state management.
///
/// Fetches unspent outputs from the domain layer and exposes it as state.
final class UtxoBloc extends Bloc<UtxoEvent, UtxoState> {
  final GetUtxosUseCase _getUtxos;

  UtxoBloc({
    required GetUtxosUseCase getUtxos,
  }) : _getUtxos = getUtxos,
       super(const UtxoState()) {
    on<UtxoListRequested>(_onUtxoListRequested);
    on<UtxoRefreshRequested>(_onUtxoRefreshRequested);
  }

  /// Handles initial list fetch — emits loading state first.
  Future<void> _onUtxoListRequested(
    UtxoListRequested event,
    Emitter<UtxoState> emit,
  ) async {
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
