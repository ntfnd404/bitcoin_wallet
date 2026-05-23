import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/core/event_bus/events/transaction_domain_event.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_action.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_event.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_state.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// Manages the mine-block regtest dev tool for multiple surfaces.
///
/// [MineBlockRequested] — address is already known (send screen post-broadcast flow).
/// [MineBlockWithWallet] — address is resolved via injected [addressResolver];
/// the BLoC does not know about wallet subtypes.
final class RegtestMiningBloc extends Bloc<RegtestMiningEvent, RegtestMiningState>
    with ActionBlocMixin<RegtestMiningState, RegtestMiningAction> {
  final BlockGenerationGateway _blockGenerationGateway;
  final AppEventBus _eventBus;
  final String _walletId;

  /// Resolves the coinbase target address from a [Wallet].
  /// Injected by [RegtestMiningScope] — the BLoC has no knowledge of wallet subtypes.
  final Future<String> Function(Wallet wallet) _addressResolver;

  RegtestMiningBloc({
    required this._blockGenerationGateway,
    required this._eventBus,
    required this._walletId,
    required this._addressResolver,
  }) : super(const RegtestMiningState()) {
    on<MineBlockRequested>(_onMineBlockRequested);
    on<MineBlockWithWallet>(_onMineBlockWithWallet);
  }

  Future<void> _onMineBlockRequested(
    MineBlockRequested event,
    Emitter<RegtestMiningState> emit,
  ) async {
    await _mine(event.toAddress, emit);
  }

  Future<void> _onMineBlockWithWallet(
    MineBlockWithWallet event,
    Emitter<RegtestMiningState> emit,
  ) async {
    emit(state.copyWith(status: RegtestMiningStatus.processing));

    final String toAddress;
    try {
      toAddress = await _addressResolver(event.wallet);
    } on TransactionException catch (e) {
      if (isClosed) return;
      emitAction(RegtestMiningFailedAction(exception: e));
      emit(state.copyWith(status: RegtestMiningStatus.idle));

      return;
    } catch (e, stack) {
      emitAction(RegtestMiningUnexpectedFailedAction());
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: RegtestMiningStatus.idle));

      return;
    }

    if (toAddress.isEmpty) {
      if (isClosed) return;
      emit(state.copyWith(status: RegtestMiningStatus.idle));

      return;
    }

    await _mine(toAddress, emit);
  }

  Future<void> _mine(String toAddress, Emitter<RegtestMiningState> emit) async {
    emit(state.copyWith(status: RegtestMiningStatus.processing));
    try {
      await _blockGenerationGateway.generateToAddress(1, toAddress);
      if (isClosed) return;
      emit(state.copyWith(status: RegtestMiningStatus.successful));
      _eventBus.emit(BlockMined(walletId: _walletId));
    } on TransactionException catch (e) {
      if (isClosed) return;
      emitAction(RegtestMiningFailedAction(exception: e));
      emit(state.copyWith(status: RegtestMiningStatus.idle));
    } catch (e, stack) {
      emitAction(RegtestMiningUnexpectedFailedAction());
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: RegtestMiningStatus.idle));
    }
  }
}
