import 'package:wallet/wallet.dart';

final class WalletState {
  final List<Wallet> wallets;
  final WalletStatus status;
  final HdWallet? pendingHdWallet;

  const WalletState({
    this.wallets = const [],
    this.status = WalletStatus.idle,
    this.pendingHdWallet,
  });

  WalletState copyWith({
    List<Wallet>? wallets,
    WalletStatus? status,
    HdWallet? pendingHdWallet,
    bool clearPendingHdWallet = false,
  }) => WalletState(
    wallets: wallets ?? this.wallets,
    status: status ?? this.status,
    pendingHdWallet: clearPendingHdWallet ? null : (pendingHdWallet ?? this.pendingHdWallet),
  );
}

enum WalletStatus { idle, processing }
