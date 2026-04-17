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

  /// Error message from the last failed operation.
  final String? errorMessage;

  const WalletState({
    this.wallets = const [],
    this.status = WalletStatus.initial,
    this.pendingWallet,
    this.pendingMnemonic,
    this.errorMessage,
  });

  WalletState copyWith({
    List<Wallet>? wallets,
    WalletStatus? status,
    Wallet? pendingWallet,
    Mnemonic? pendingMnemonic,
    String? errorMessage,
    bool clearPendingWallet = false,
    bool clearPendingMnemonic = false,
    bool clearErrorMessage = false,
  }) => WalletState(
    wallets: wallets ?? this.wallets,
    status: status ?? this.status,
    pendingWallet: clearPendingWallet ? null : (pendingWallet ?? this.pendingWallet),
    pendingMnemonic: clearPendingMnemonic ? null : (pendingMnemonic ?? this.pendingMnemonic),
    errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
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
