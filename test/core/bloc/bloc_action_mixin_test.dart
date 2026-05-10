import 'dart:async';

import 'package:bitcoin_wallet/core/bloc/bloc_action_mixin.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// Minimal BLoC stub for testing the mixin in isolation.
final class _TestBloc extends Bloc<Object, int>
    with BlocActionMixin<int, String> {
  _TestBloc() : super(0) {
    on<Object>((_, emit) => emit(state + 1));
  }
}

void main() {
  group('BlocActionMixin', () {
    late _TestBloc bloc;

    setUp(() => bloc = _TestBloc());
    tearDown(() => bloc.close());

    test('emitAction delivers action to stream subscriber', () async {
      final received = <String>[];
      bloc.actionStream.listen(received.add);

      bloc.emitAction('hello');
      await Future<void>.delayed(Duration.zero);

      expect(received, ['hello']);
    });

    test('emitAction after close() is a no-op', () async {
      final received = <String>[];
      bloc.actionStream.listen(received.add);

      await bloc.close();
      bloc.emitAction('should not arrive');
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
    });

    test('broadcast: two subscribers each receive independently', () async {
      final a = <String>[];
      final b = <String>[];
      bloc.actionStream.listen(a.add);
      bloc.actionStream.listen(b.add);

      bloc.emitAction('ping');
      await Future<void>.delayed(Duration.zero);

      expect(a, ['ping']);
      expect(b, ['ping']);
    });

    test('late subscriber does not receive past action', () async {
      bloc.emitAction('past');
      await Future<void>.delayed(Duration.zero);

      final received = <String>[];
      bloc.actionStream.listen(received.add);
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
    });

    test('close() completes the stream', () async {
      final done = Completer<void>();
      bloc.actionStream.listen((_) {}, onDone: done.complete);

      await bloc.close();

      expect(done.isCompleted, isTrue);
    });
  });
}
