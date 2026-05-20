import 'dart:async';

import 'package:action_bloc/src/action_bloc_observer.dart';
import 'package:action_bloc/src/action_bloc_streamable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Adds a one-shot action stream to any [BlocBase].
///
/// Actions are fire-and-forget UI effects (SnackBar, navigation, focus).
/// They are NOT stored in state — they arrive once and are consumed.
///
/// Usage:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState>
///     with ActionBlocMixin<MyState, MyAction> { ... }
/// ```
mixin ActionBlocMixin<S, A> on BlocBase<S> implements ActionBlocStateStreamable<S, A> {
  final StreamController<A> _actionController = StreamController<A>.broadcast();

  /// Broadcast stream of one-shot UI actions.
  ///
  /// Late subscribers do not receive past actions.
  @override
  Stream<A> get actionStream => _actionController.stream;

  /// Emits [action] to all current [actionStream] subscribers.
  ///
  /// No-op if the BLoC is already closed.
  void emitAction(A action) {
    if (!isClosed) {
      final observer = Bloc.observer;
      if (observer case final ActionBlocObserver actionObserver) {
        actionObserver.onAction(this, action);
      }
      _actionController.add(action);
    }
  }

  @override
  Future<void> close() async {
    await _actionController.close();

    return super.close();
  }
}
