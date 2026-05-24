import 'package:action_bloc/action_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stubs/stub_action_bloc.dart';

void main() {
  group('ActionBlocConsumer', () {
    testWidgets('actionListener fires with current state on action', (tester) async {
      final bloc = StubActionBloc();
      addTearDown(bloc.close);
      final received = <(int, String)>[];

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: ActionBlocConsumer<StubActionBloc, int, String>(
              actionListener: (_, state, action) => received.add((state, action)),
              builder: (_, state) => Text('$state'),
            ),
          ),
        ),
      );

      bloc.emitAction('hello');
      await tester.pump();

      expect(received, [(0, 'hello')]);
    });

    testWidgets('stateListener fires on state change', (tester) async {
      final bloc = StubActionBloc();
      addTearDown(bloc.close);
      final states = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: ActionBlocConsumer<StubActionBloc, int, String>(
              stateListener: (_, state) => states.add(state),
              builder: (_, state) => Text('count:$state'),
            ),
          ),
        ),
      );

      bloc.add(Object());
      await tester.pump();

      expect(states, [1]);
    });

    testWidgets('builder rebuilds on state change', (tester) async {
      final bloc = StubActionBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: ActionBlocConsumer<StubActionBloc, int, String>(
              builder: (_, state) => Text('count:$state'),
            ),
          ),
        ),
      );

      expect(find.text('count:0'), findsOneWidget);

      bloc.add(Object());
      await tester.pump();

      expect(find.text('count:1'), findsOneWidget);
    });

    testWidgets('actionListenWhen filters actions', (tester) async {
      final bloc = StubActionBloc();
      addTearDown(bloc.close);
      final received = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: ActionBlocConsumer<StubActionBloc, int, String>(
              actionListenWhen: (action) => action != 'skip',
              actionListener: (_, _, action) => received.add(action),
              builder: (_, state) => Text('$state'),
            ),
          ),
        ),
      );

      bloc.emitAction('pass');
      bloc.emitAction('skip');
      bloc.emitAction('pass');
      await tester.pump();

      expect(received, ['pass', 'pass']);
    });
  });
}
