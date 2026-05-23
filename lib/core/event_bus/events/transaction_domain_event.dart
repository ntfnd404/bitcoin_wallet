import 'package:bitcoin_wallet/core/event_bus/domain_event.dart';

/// Group of events related to transaction lifecycle.
///
/// Emitters: [SendBloc] (after send/mine), [SigningBloc] (after broadcast).
/// Listeners: [TransactionBloc], [UtxoBloc] (auto-refresh on event).
sealed class TransactionDomainEvent extends DomainEvent {
  /// The wallet that this event is scoped to.
  ///
  /// Listeners use this to skip events for wallets they are not displaying.
  String get walletId;

  const TransactionDomainEvent();
}

/// Emitted after a transaction is successfully broadcast to the network.
final class TransactionBroadcasted extends TransactionDomainEvent {
  final String txid;
  @override
  final String walletId;

  const TransactionBroadcasted({required this.txid, required this.walletId});
}

/// Emitted after a regtest block is mined (confirming pending transactions).
final class BlockMined extends TransactionDomainEvent {
  @override
  final String walletId;

  const BlockMined({required this.walletId});
}
