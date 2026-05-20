import 'package:flutter_bloc/flutter_bloc.dart';

/// Observes one-shot actions emitted by BLoCs that use [ActionBlocMixin].
///
/// Actions are separate from regular BLoC events: events are inputs handled by
/// `Bloc.add`, while actions are fire-and-forget UI effects emitted through
/// `emitAction`.
///
/// To observe actions globally, make the configured [Bloc.observer] implement
/// this interface.
abstract interface class ActionBlocObserver {
  void onAction(BlocBase<dynamic> bloc, Object? action);
}
