import 'package:flutter/foundation.dart';

/// Snapshot of an action transition: what was emitted just before [current]
/// and what is being emitted now.
///
/// [previous] is null on the very first [emitAction] call after BLoC creation.
@immutable
final class ActionChange<A> {
  final A? previous;
  final A current;

  @override
  int get hashCode => Object.hash(previous, current);

  const ActionChange({this.previous, required this.current});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ActionChange<A> && previous == other.previous && current == other.current;

  @override
  String toString() => 'ActionChange(previous: $previous, current: $current)';
}
