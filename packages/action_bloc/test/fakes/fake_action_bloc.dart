import 'dart:async';

import 'package:action_bloc/action_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Fake [Bloc] that manually controls action emission without [ActionBlocMixin].
///
/// Used to verify that [ActionBlocListener] works with any [ActionBlocStateStreamable]
/// implementation, not only with [ActionBlocMixin].
final class FakeActionBloc extends Bloc<Object, int> implements ActionBlocStateStreamable<int, String> {
  final StreamController<String> _actionController = StreamController<String>.broadcast();

  @override
  Stream<String> get actionStream => _actionController.stream;

  FakeActionBloc() : super(0);

  void emitAction(String action) => _actionController.add(action);

  @override
  Future<void> close() async {
    await _actionController.close();

    return super.close();
  }
}
