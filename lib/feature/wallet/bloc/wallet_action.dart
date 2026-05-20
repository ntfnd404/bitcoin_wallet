import 'package:keys/keys.dart';
import 'package:wallet/wallet.dart';

sealed class WalletAction {}

// Navigation actions — replace pendingWallet / pendingMnemonic state fields

/// Node wallet was created; navigate to wallet detail.
final class WalletNodeCreatedAction extends WalletAction {
  final NodeWallet wallet;

  WalletNodeCreatedAction({required this.wallet});
}

/// HD wallet was created; navigate to seed phrase confirmation screen.
final class WalletHdAwaitingConfirmationAction extends WalletAction {
  final HdWallet wallet;
  final Mnemonic mnemonic;

  WalletHdAwaitingConfirmationAction({required this.wallet, required this.mnemonic});
}

/// HD wallet seed was confirmed; wallet added to list — pop CreateWalletScreen.
final class WalletHdConfirmedAction extends WalletAction {
  final HdWallet wallet;

  WalletHdConfirmedAction({required this.wallet});
}

/// HD wallet was restored; navigate back to wallet list.
final class WalletRestoredAction extends WalletAction {
  final HdWallet wallet;

  WalletRestoredAction({required this.wallet});
}

/// Seed was loaded for view; navigate to seed phrase screen.
final class WalletSeedReadyAction extends WalletAction {
  final Mnemonic mnemonic;

  WalletSeedReadyAction({required this.mnemonic});
}

// Error actions — replace Exception? exception state field

/// A wallet operation failed (load, create, restore).
final class WalletErrorOccurredAction extends WalletAction {
  final WalletException exception;

  WalletErrorOccurredAction({required this.exception});
}

/// Seed retrieval failed.
final class WalletSeedFailedAction extends WalletAction {
  final KeysException exception;

  WalletSeedFailedAction({required this.exception});
}
