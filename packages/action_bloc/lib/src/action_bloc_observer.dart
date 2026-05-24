import 'package:action_bloc/src/action_change.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Observes one-shot actions emitted by BLoCs that use [ActionBlocMixin].
///
/// Mix this into your [BlocObserver] subclass and override [onAction]
/// to receive action-transition events globally:
///
/// ```dart
/// final class AppBlocObserver extends BlocObserver with ActionBlocObserver {
///   @override
///   void onAction(BlocBase<Object?> bloc, ActionChange<Object?> change) {
///     log('${bloc.runtimeType}: ${change.current}');
///   }
/// }
/// ```
///
/// The default implementation is a no-op, so you only override what you need.
mixin ActionBlocObserver {
  /// Called each time [emitAction] is invoked on a BLoC.
  ///
  /// [change.previous] is null on the first emission after BLoC creation.
  void onAction(BlocBase<Object?> _, ActionChange<Object?> _) {}
}
