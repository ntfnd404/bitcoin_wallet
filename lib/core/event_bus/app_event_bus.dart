import 'dart:async';

import 'package:bitcoin_wallet/core/event_bus/domain_event.dart';

/// Application-wide broadcast event bus for cross-feature communication.
///
/// BLoCs subscribe in their constructor and unsubscribe in [close()].
/// Features must not import each other's BLoC layers directly — use
/// this bus instead.
///
/// Usage (emitter):
/// ```dart
/// _eventBus.emit(TransactionBroadcasted(txid: txid, walletId: id));
/// ```
///
/// Usage (listener):
/// ```dart
/// _sub = _eventBus.stream.listen((event) {
///   if (event is TransactionEvent) _handleTransactionEvent(event);
/// });
/// ```
final class AppEventBus {
  final _controller = StreamController<DomainEvent>.broadcast();

  Stream<T> on<T extends DomainEvent>() => _controller.stream.where((e) => e is T).cast<T>();

  void emit(DomainEvent event) => _controller.add(event);

  void dispose() => _controller.close();
}
