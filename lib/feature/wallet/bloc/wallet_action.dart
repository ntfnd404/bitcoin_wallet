import 'package:keys/keys.dart';
import 'package:wallet/wallet.dart';

sealed class WalletAction {}

// Navigation actions — replace pendingWallet / pendingMnemonic state fields

/// Node wallet was created; navigate to wallet detail.
final class WalletNodeCreated extends WalletAction {
  final NodeWallet wallet;

  WalletNodeCreated({required this.wallet});
}

/// HD wallet was created; navigate to seed phrase confirmation screen.
final class WalletHdAwaitingConfirmation extends WalletAction {
  final HdWallet wallet;
  final Mnemonic mnemonic;

  WalletHdAwaitingConfirmation({required this.wallet, required this.mnemonic});
}

/// HD wallet seed was confirmed; wallet added to list — pop CreateWalletScreen.
final class WalletHdConfirmed extends WalletAction {
  final HdWallet wallet;

  WalletHdConfirmed({required this.wallet});
}

/// HD wallet was restored; navigate back to wallet list.
final class WalletRestored extends WalletAction {
  final HdWallet wallet;

  WalletRestored({required this.wallet});
}

/// Seed was loaded for view; navigate to seed phrase screen.
final class WalletSeedReady extends WalletAction {
  final Mnemonic mnemonic;

  WalletSeedReady({required this.mnemonic});
}

// Error actions — replace Exception? exception state field

/// A wallet operation failed (load, create, restore).
final class WalletErrorOccurred extends WalletAction {
  final WalletException exception;

  WalletErrorOccurred({required this.exception});
}

/// Seed retrieval failed.
final class WalletSeedFailed extends WalletAction {
  final KeysException exception;

  WalletSeedFailed({required this.exception});
}
