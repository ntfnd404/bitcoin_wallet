import 'dart:async';

import 'package:bitcoin_wallet/core/event_bus/domain_event.dart';

/// In-process broadcast bus for application-level domain events.
///
/// Use this for decoupled notifications between independently owned parts of
/// an application. Event producers publish immutable [DomainEvent] objects with
/// [emit], and consumers subscribe to the event type they care about with
/// [on<T>].
///
/// The bus is intentionally a regular object, not a global singleton. Create it
/// in the application's composition root and pass it through dependency
/// injection. The same owner that creates the bus should call [dispose] when the
/// application scope is torn down.
///
/// Subscribers own their subscriptions and must cancel them with the rest of
/// their lifecycle.
///
/// Example:
/// ```dart
/// sealed class ItemDomainEvent extends DomainEvent {
///   const ItemDomainEvent();
/// }
///
/// final class ItemCreated extends ItemDomainEvent {
///   final String itemId;
///
///   const ItemCreated(this.itemId);
/// }
///
/// eventBus.emit(const ItemCreated('item-1'));
///
/// final subscription = eventBus.on<ItemCreated>().listen((event) {
///   // React to event.itemId.
/// });
///
/// await subscription.cancel();
/// ```
final class AppEventBus {
  final _controller = StreamController<DomainEvent>.broadcast();

  Stream<T> on<T extends DomainEvent>() => _controller.stream.where((e) => e is T).cast<T>();

  void emit(DomainEvent event) => _controller.add(event);

  void dispose() => _controller.close();
}
