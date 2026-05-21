import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_action.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_event.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keys/keys.dart';
import 'package:wallet/wallet.dart';

final class WalletBloc extends Bloc<WalletEvent, WalletState> with ActionBlocMixin<WalletState, WalletAction> {
  final WalletRepository _walletRepository;
  final GetSeedUseCase _getSeed;
  final CreateNodeWalletUseCase _createNodeWallet;
  final CreateHdWalletUseCase _createHdWallet;
  final RestoreHdWalletUseCase _restoreHdWallet;

  WalletBloc({
    required this._walletRepository,
    required this._getSeed,
    required this._createNodeWallet,
    required this._createHdWallet,
    required this._restoreHdWallet,
  }) : super(const WalletState()) {
    on<WalletListRequested>(_onWalletListRequested);
    on<NodeWalletCreateRequested>(_onNodeWalletCreateRequested);
    on<HdWalletCreateRequested>(_onHdWalletCreateRequested);
    on<WalletRestoreRequested>(_onWalletRestoreRequested);
    on<SeedConfirmed>(_onSeedConfirmed);
    on<SeedViewRequested>(_onSeedViewRequested);
  }

  Future<void> _onWalletListRequested(
    WalletListRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.processing));
    try {
      final wallets = await _walletRepository.getWallets();
      if (isClosed) return;

      emit(state.copyWith(status: WalletStatus.idle, wallets: wallets));
    } on WalletException catch (e) {
      if (isClosed) return;
      emitAction(WalletErrorOccurredAction(exception: e));
      emit(state.copyWith(status: WalletStatus.idle));
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: WalletStatus.idle));
    }
  }

  Future<void> _onNodeWalletCreateRequested(
    NodeWalletCreateRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.processing));
    try {
      final wallet = await _createNodeWallet(event.name);
      if (isClosed) return;

      emit(state.copyWith(status: WalletStatus.idle, wallets: [...state.wallets, wallet]));
      emitAction(WalletNodeCreatedAction(wallet: wallet));
    } on WalletException catch (e) {
      if (isClosed) return;
      emitAction(WalletErrorOccurredAction(exception: e));
      emit(state.copyWith(status: WalletStatus.idle));
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: WalletStatus.idle));
    }
  }

  Future<void> _onHdWalletCreateRequested(
    HdWalletCreateRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.processing));
    try {
      final (wallet, mnemonic) = await _createHdWallet(event.name, wordCount: event.wordCount);
      if (isClosed) return;

      emit(state.copyWith(status: WalletStatus.idle, pendingHdWallet: wallet));
      emitAction(WalletHdAwaitingConfirmationAction(wallet: wallet, mnemonic: mnemonic));
    } on WalletException catch (e) {
      if (isClosed) return;
      emitAction(WalletErrorOccurredAction(exception: e));
      emit(state.copyWith(status: WalletStatus.idle));
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: WalletStatus.idle));
    }
  }

  Future<void> _onWalletRestoreRequested(
    WalletRestoreRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.processing));
    try {
      final wallet = await _restoreHdWallet(event.name, event.mnemonic);
      if (isClosed) return;

      emit(state.copyWith(status: WalletStatus.idle, wallets: [...state.wallets, wallet]));
      emitAction(WalletRestoredAction(wallet: wallet));
    } on WalletException catch (e) {
      if (isClosed) return;
      emitAction(WalletErrorOccurredAction(exception: e));
      emit(state.copyWith(status: WalletStatus.idle));
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: WalletStatus.idle));
    }
  }

  void _onSeedConfirmed(SeedConfirmed event, Emitter<WalletState> emit) {
    final confirmed = state.pendingHdWallet;
    if (confirmed == null) return;

    emit(
      state.copyWith(
        status: WalletStatus.idle,
        wallets: [...state.wallets, confirmed],
        clearPendingHdWallet: true,
      ),
    );
    emitAction(WalletHdConfirmedAction(wallet: confirmed));
  }

  Future<void> _onSeedViewRequested(
    SeedViewRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.processing));
    try {
      final mnemonic = await _getSeed(event.walletId);
      if (isClosed) return;

      emit(state.copyWith(status: WalletStatus.idle));
      emitAction(WalletSeedReadyAction(mnemonic: mnemonic));
    } on KeysException catch (e) {
      if (isClosed) return;
      emitAction(WalletSeedFailedAction(exception: e));
      emit(state.copyWith(status: WalletStatus.idle));
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: WalletStatus.idle));
    }
  }
}
