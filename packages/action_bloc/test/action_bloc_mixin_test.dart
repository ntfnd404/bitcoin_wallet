import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/spy_action_bloc_observer.dart';
import 'stubs/stub_action_bloc.dart';

void main() {
  group('ActionBlocMixin', () {
    late StubActionBloc bloc;
    late BlocObserver previousObserver;

    setUp(() {
      previousObserver = Bloc.observer;
      bloc = StubActionBloc();
    });

    tearDown(() async {
      Bloc.observer = previousObserver;
      if (!bloc.isClosed) await bloc.close();
    });

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

    test('emitAction notifies registered action observer', () async {
      final observer = SpyActionBlocObserver();
      Bloc.observer = observer;

      bloc.emitAction('hello');
      await Future<void>.delayed(Duration.zero);

      expect(observer.records, [
        (bloc: bloc, action: 'hello'),
      ]);
    });

    test('close() completes the stream', () async {
      final done = Completer<void>();
      bloc.actionStream.listen((_) {}, onDone: done.complete);

      await bloc.close();

      expect(done.isCompleted, isTrue);
    });
  });
}

