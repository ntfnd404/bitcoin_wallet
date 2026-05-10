import 'package:bitcoin_wallet/core/event_bus/app_event.dart';

/// Group of events related to transaction lifecycle.
///
/// Emitters: [SendBloc] (after send/mine), [SigningBloc] (after broadcast).
/// Listeners: [TransactionBloc], [UtxoBloc] (auto-refresh on event).
sealed class TransactionEvent extends AppEvent {
  /// The wallet that this event is scoped to.
  ///
  /// Listeners use this to skip events for wallets they are not displaying.
  String get walletId;

  const TransactionEvent();
}

/// Emitted after a transaction is successfully broadcast to the network.
final class TransactionBroadcasted extends TransactionEvent {
  final String txid;
  @override
  final String walletId;

  const TransactionBroadcasted({required this.txid, required this.walletId});
}

/// Emitted after a regtest block is mined (confirming pending transactions).
final class BlockMined extends TransactionEvent {
  @override
  final String walletId;

  const BlockMined({required this.walletId});
}
