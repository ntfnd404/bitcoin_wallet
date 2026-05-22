import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_picker/utxo_picker_action.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_picker/utxo_picker_event.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_picker/utxo_picker_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

/// BLoC for the UTXO picker screen.
///
/// Owns a frozen snapshot of the wallet's spendable UTXOs — no auto-refresh
/// on transaction events. The developer's selection is preserved across
/// back-navigation from [SendScreen] because this BLoC lives above both
/// screens in the navigation stack.
final class UtxoPickerBloc extends Bloc<UtxoPickerEvent, UtxoPickerState>
    with ActionBlocMixin<UtxoPickerState, UtxoPickerAction> {
  final UtxoRepository _utxoRepository;
  final FeeEstimator _feeEstimator;

  UtxoPickerBloc({
    required this._utxoRepository,
    required this._feeEstimator,
  }) : super(const UtxoPickerState()) {
    on<UtxoPickerLoaded>(_onLoaded);
    on<UtxoPickerSelectionToggled>(_onToggled);
    on<UtxoPickerFeeRateChanged>(_onFeeRateChanged);
  }

  Future<void> _onLoaded(
    UtxoPickerLoaded event,
    Emitter<UtxoPickerState> emit,
  ) async {
    emit(state.copyWith(status: FetchStatus.processing));
    try {
      final all = await _utxoRepository.getUtxos(event.walletName);
      if (isClosed) return;

      final spendable = all.where((u) => u.spendable).toList();

      emit(state.copyWith(utxos: spendable, status: FetchStatus.idle));
    } on TransactionException catch (e) {
      emitAction(UtxoPickerLoadFailedAction(exception: e));
      if (isClosed) return;
      emit(state.copyWith(status: FetchStatus.idle));
    } catch (e, stack) {
      emitAction(UtxoPickerUnexpectedFailedAction());
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: FetchStatus.idle));
    }
  }

  void _onToggled(
    UtxoPickerSelectionToggled event,
    Emitter<UtxoPickerState> emit,
  ) {
    final key = '${event.txid}:${event.vout}';
    final next = Set<String>.of(state.selectedKeys);

    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }

    emit(_withComputedTotals(state.copyWith(selectedKeys: next)));
  }

  void _onFeeRateChanged(
    UtxoPickerFeeRateChanged event,
    Emitter<UtxoPickerState> emit,
  ) {
    emit(
      _withComputedTotals(
        state.copyWith(feeRateSatPerVbyte: event.feeRateSatPerVbyte),
      ),
    );
  }

  /// Recomputes [inputSumSat], [estimatedFeeSat], [estimatedChangeSat] from
  /// the current selection and fee rate.
  UtxoPickerState _withComputedTotals(UtxoPickerState s) {
    final selected = s.selectedUtxos;

    if (selected.isEmpty) {
      return s.copyWith(
        inputSumSat: Satoshi.zero,
        estimatedFeeSat: Satoshi.zero,
        estimatedChangeSat: Satoshi.zero,
      );
    }

    final inputSum = selected.fold(
      Satoshi.zero,
      (acc, u) => acc + u.amountSat,
    );

    final candidates = selected
        .map(
          (u) => CoinCandidate(
            txid: u.txid,
            vout: u.vout,
            amountSat: u.amountSat,
            age: u.confirmations,
            scriptType: u.type,
            scriptPubKeyHex: u.scriptPubKey,
            confirmations: u.confirmations,
          ),
        )
        .toList();

    final fee = _feeEstimator.estimateForCandidates(
      inputs: candidates,
      outputs: 2,
      feeRateSatPerVbyte: s.feeRateSatPerVbyte,
    );

    final changeRaw = inputSum.value - fee.value;
    final change = changeRaw > 0 ? Satoshi(changeRaw) : Satoshi.zero;

    return s.copyWith(
      inputSumSat: inputSum,
      estimatedFeeSat: fee,
      estimatedChangeSat: change,
    );
  }
}
