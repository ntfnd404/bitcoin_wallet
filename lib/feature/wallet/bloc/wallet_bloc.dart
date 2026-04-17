import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_event.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keys/keys.dart';
import 'package:wallet/wallet.dart';

final class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository _walletRepository;
  final SeedRepository _seedRepository;
  final CreateNodeWalletUseCase _createNodeWallet;
  final CreateHdWalletUseCase _createHdWallet;
  final RestoreHdWalletUseCase _restoreHdWallet;

  WalletBloc({
    required WalletRepository walletRepository,
    required SeedRepository seedRepository,
    required CreateNodeWalletUseCase createNodeWallet,
    required CreateHdWalletUseCase createHdWallet,
    required RestoreHdWalletUseCase restoreHdWallet,
  }) : _walletRepository = walletRepository,
       _seedRepository = seedRepository,
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
    emit(state.copyWith(status: WalletStatus.loading, clearErrorMessage: true));
    try {
      final wallets = await _walletRepository.getWallets();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: WalletStatus.loaded,
          wallets: wallets,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: WalletStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onNodeWalletCreateRequested(
    NodeWalletCreateRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.creating, clearErrorMessage: true));
    try {
      final wallet = await _createNodeWallet(event.name);
      if (isClosed) return;

      emit(
        state.copyWith(
          status: WalletStatus.loaded,
          wallets: [...state.wallets, wallet],
          pendingWallet: wallet,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: WalletStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onHdWalletCreateRequested(
    HdWalletCreateRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.creating, clearErrorMessage: true));
    try {
      final (wallet, mnemonic) = await _createHdWallet(
        event.name,
        wordCount: event.wordCount,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: WalletStatus.awaitingSeedConfirmation,
          pendingWallet: wallet,
          pendingMnemonic: mnemonic,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: WalletStatus.error,
          errorMessage: e.toString(),
          clearPendingWallet: true,
          clearPendingMnemonic: true,
        ),
      );
    }
  }

  Future<void> _onWalletRestoreRequested(
    WalletRestoreRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.creating, clearErrorMessage: true));
    try {
      final wallet = await _restoreHdWallet(event.name, event.mnemonic);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: WalletStatus.loaded,
          wallets: [...state.wallets, wallet],
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: WalletStatus.error, errorMessage: e.toString()));
    }
  }

  void _onSeedConfirmed(
    SeedConfirmed event,
    Emitter<WalletState> emit,
  ) {
    final confirmed = state.pendingWallet;
    if (confirmed == null) return;

    emit(
      state.copyWith(
        status: WalletStatus.loaded,
        wallets: [...state.wallets, confirmed],
        clearPendingWallet: true,
        clearPendingMnemonic: true,
      ),
    );
  }

  Future<void> _onSeedViewRequested(
    SeedViewRequested event,
    Emitter<WalletState> emit,
  ) async {
    try {
      final mnemonic = await _seedRepository.getSeed(event.walletId);
      if (isClosed) return;
      if (mnemonic == null) {
        emit(
          state.copyWith(
            status: WalletStatus.error,
            errorMessage: 'Seed not found for wallet ${event.walletId}',
          ),
        );

        return;
      }
      emit(
        state.copyWith(
          status: WalletStatus.awaitingSeedConfirmation,
          pendingMnemonic: mnemonic,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: WalletStatus.error, errorMessage: e.toString()));
    }
  }
}
