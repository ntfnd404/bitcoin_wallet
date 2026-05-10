import 'package:keys/keys.dart';
import 'package:wallet/wallet.dart';

final class WalletState {
  /// All persisted wallets.
  final List<Wallet> wallets;

  /// Current operation status.
  final WalletStatus status;

  /// Wallet awaiting action:
  /// - For Node wallets: populated when creation completes, used to navigate to detail
  /// - For HD wallets: populated when creation/restore completes, awaiting seed confirmation
  /// Cleared after confirmation or error.
  final Wallet? pendingWallet;

  /// Generated or restored mnemonic, populated only for HD wallets during [awaitingSeedConfirmation].
  /// Cleared after confirmation or error.
  final Mnemonic? pendingMnemonic;

  /// Exception from the last failed operation.
  final Exception? exception;

  const WalletState({
    this.wallets = const [],
    this.status = WalletStatus.initial,
    this.pendingWallet,
    this.pendingMnemonic,
    this.exception,
  });

  WalletState copyWith({
    List<Wallet>? wallets,
    WalletStatus? status,
    Wallet? pendingWallet,
    Mnemonic? pendingMnemonic,
    Exception? exception,
    bool clearPendingWallet = false,
    bool clearPendingMnemonic = false,
    bool clearException = false,
  }) => WalletState(
    wallets: wallets ?? this.wallets,
    status: status ?? this.status,
    pendingWallet: clearPendingWallet ? null : (pendingWallet ?? this.pendingWallet),
    pendingMnemonic: clearPendingMnemonic ? null : (pendingMnemonic ?? this.pendingMnemonic),
    exception: clearException ? null : (exception ?? this.exception),
  );
}

enum WalletStatus {
  initial,
  loading,
  loaded,
  creating,
  awaitingSeedConfirmation,
  error,
}
