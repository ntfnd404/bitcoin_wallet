import 'package:keys/keys.dart';

sealed class WalletEvent {
  const WalletEvent();
}

final class WalletListRequested extends WalletEvent {
  const WalletListRequested();
}

final class NodeWalletCreateRequested extends WalletEvent {
  final String name;

  const NodeWalletCreateRequested({required this.name});
}

final class HdWalletCreateRequested extends WalletEvent {
  final String name;
  final int wordCount;

  const HdWalletCreateRequested({required this.name, this.wordCount = 12});
}

final class WalletRestoreRequested extends WalletEvent {
  final String name;
  final Mnemonic mnemonic;

  const WalletRestoreRequested({required this.name, required this.mnemonic});
}

final class SeedConfirmed extends WalletEvent {
  final String walletId;

  const SeedConfirmed({required this.walletId});
}

final class SeedViewRequested extends WalletEvent {
  final String walletId;

  const SeedViewRequested({required this.walletId});
}
