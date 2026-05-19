import 'package:flutter_bloc/flutter_bloc.dart';

/// Exposes a stream of one-shot actions.
abstract interface class ActionBlocStreamable<A> {
  Stream<A> get actionStream;
}

/// Exposes regular BLoC state plus one-shot actions.
abstract interface class ActionBlocStateStreamable<S, A> implements StateStreamable<S>, ActionBlocStreamable<A> {}
