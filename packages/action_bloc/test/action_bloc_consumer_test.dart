import 'package:action_bloc/action_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stubs/stub_action_bloc.dart';

void main() {
  group('ActionBlocConsumer', () {
    testWidgets('listener fires on action', (tester) async {
      final bloc = StubActionBloc();
      addTearDown(bloc.close);
      final received = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: ActionBlocConsumer<StubActionBloc, int, String>(
              listener: (_, action) => received.add(action),
              builder: (_, state) => Text('$state'),
            ),
          ),
        ),
      );

      bloc.emitAction('hello');
      await tester.pump();

      expect(received, ['hello']);
    });

    testWidgets('builder rebuilds on state change', (tester) async {
      final bloc = StubActionBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: ActionBlocConsumer<StubActionBloc, int, String>(
              listener: (context, action) {},
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
  });
}
