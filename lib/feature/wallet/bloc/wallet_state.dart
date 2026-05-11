import 'package:wallet/wallet.dart';

final class WalletState {
  final List<Wallet> wallets;
  final WalletStatus status;

  const WalletState({
    this.wallets = const [],
    this.status = WalletStatus.initial,
  });

  WalletState copyWith({
    List<Wallet>? wallets,
    WalletStatus? status,
  }) => WalletState(
    wallets: wallets ?? this.wallets,
    status: status ?? this.status,
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
