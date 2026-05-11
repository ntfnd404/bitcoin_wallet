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

  // Holds the pending HD wallet between HdWalletCreateRequested and SeedConfirmed.
  HdWallet? _pendingHdWallet;

  WalletBloc({
    required WalletRepository walletRepository,
    required GetSeedUseCase getSeed,
    required CreateNodeWalletUseCase createNodeWallet,
    required CreateHdWalletUseCase createHdWallet,
    required RestoreHdWalletUseCase restoreHdWallet,
  }) : _walletRepository = walletRepository,
       _getSeed = getSeed,
       _createNodeWallet = createNodeWallet,
       _createHdWallet = createHdWallet,
       _restoreHdWallet = restoreHdWallet,
       super(const WalletState()) {
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
    emit(state.copyWith(status: WalletStatus.loading));
    try {
      final wallets = await _walletRepository.getWallets();
      if (isClosed) return;
      emit(state.copyWith(status: WalletStatus.loaded, wallets: wallets));
    } on WalletException catch (e) {
      if (isClosed) return;
      emitAction(WalletErrorOccurred(exception: e));
      emit(state.copyWith(status: WalletStatus.error));
    } catch (e, stack) {
      Error.throwWithStackTrace(e, stack);
    }
  }

  Future<void> _onNodeWalletCreateRequested(
    NodeWalletCreateRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.creating));
    try {
      final wallet = await _createNodeWallet(event.name);
      if (isClosed) return;
      emit(state.copyWith(status: WalletStatus.loaded, wallets: [...state.wallets, wallet]));
      emitAction(WalletNodeCreated(wallet: wallet));
    } on WalletException catch (e) {
      if (isClosed) return;
      emitAction(WalletErrorOccurred(exception: e));
      emit(state.copyWith(status: WalletStatus.error));
    } catch (e, stack) {
      Error.throwWithStackTrace(e, stack);
    }
  }

  Future<void> _onHdWalletCreateRequested(
    HdWalletCreateRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.creating));
    try {
      final (wallet, mnemonic) = await _createHdWallet(event.name, wordCount: event.wordCount);
      if (isClosed) return;
      _pendingHdWallet = wallet;
      emit(state.copyWith(status: WalletStatus.awaitingSeedConfirmation));
      emitAction(WalletHdAwaitingConfirmation(wallet: wallet, mnemonic: mnemonic));
    } on WalletException catch (e) {
      if (isClosed) return;
      _pendingHdWallet = null;
      emitAction(WalletErrorOccurred(exception: e));
      emit(state.copyWith(status: WalletStatus.error));
    } catch (e, stack) {
      Error.throwWithStackTrace(e, stack);
    }
  }

  Future<void> _onWalletRestoreRequested(
    WalletRestoreRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.creating));
    try {
      final wallet = await _restoreHdWallet(event.name, event.mnemonic);
      if (isClosed) return;
      emit(state.copyWith(status: WalletStatus.loaded, wallets: [...state.wallets, wallet]));
      emitAction(WalletRestored(wallet: wallet));
    } on WalletException catch (e) {
      if (isClosed) return;
      emitAction(WalletErrorOccurred(exception: e));
      emit(state.copyWith(status: WalletStatus.error));
    } catch (e, stack) {
      Error.throwWithStackTrace(e, stack);
    }
  }

  void _onSeedConfirmed(SeedConfirmed event, Emitter<WalletState> emit) {
    final confirmed = _pendingHdWallet;
    if (confirmed == null) return;
    _pendingHdWallet = null;

    emit(state.copyWith(status: WalletStatus.loaded, wallets: [...state.wallets, confirmed]));
    emitAction(WalletHdConfirmed(wallet: confirmed));
  }

  Future<void> _onSeedViewRequested(
    SeedViewRequested event,
    Emitter<WalletState> emit,
  ) async {
    try {
      final mnemonic = await _getSeed(event.walletId);
      if (isClosed) return;
      emit(state.copyWith(status: WalletStatus.awaitingSeedConfirmation));
      emitAction(WalletSeedReady(mnemonic: mnemonic));
    } on KeysException catch (e) {
      if (isClosed) return;
      emitAction(WalletSeedFailed(exception: e));
      emit(state.copyWith(status: WalletStatus.error));
    } catch (e, stack) {
      Error.throwWithStackTrace(e, stack);
    }
  }
}
