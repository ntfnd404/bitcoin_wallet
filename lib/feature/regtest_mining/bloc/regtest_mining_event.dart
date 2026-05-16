import 'package:wallet/wallet.dart';

sealed class RegtestMiningEvent {
  const RegtestMiningEvent();
}

/// Mine one block to a known address (send screen flow — address from SendState).
final class MineBlockRequested extends RegtestMiningEvent {
  final String toAddress;

  const MineBlockRequested({required this.toAddress});
}

/// Mine one block resolving the target address from the wallet (wallet detail flow).
final class MineBlockWithWallet extends RegtestMiningEvent {
  final Wallet wallet;

  const MineBlockWithWallet({required this.wallet});
}
