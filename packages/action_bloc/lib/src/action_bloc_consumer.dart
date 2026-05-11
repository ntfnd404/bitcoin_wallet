import 'package:action_bloc/src/action_bloc_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Combines [ActionBlocListener] and [BlocBuilder] into a single widget.
///
/// If [bloc] is omitted the nearest [BlocProvider] ancestor is used.
///
/// Usage:
/// ```dart
/// ActionBlocConsumer<MyBloc, MyState, MyAction>(
///   listener: (context, action) => switch (action) {
///     MyError(:final exception) => showSnackBar(exception.toString()),
///     _ => null,
///   },
///   builder: (context, state) => Text(state.value),
/// )
/// ```
class ActionBlocConsumer<B extends BlocBase<S>, S, A> extends StatelessWidget {
  const ActionBlocConsumer({
    super.key,
    required this.listener,
    required this.builder,
    this.bloc,
    this.listenWhen,
    this.buildWhen,
  });

  /// The BLoC to subscribe to. When null, resolved via [context.read].
  final B? bloc;

  /// Called for each action emitted by the BLoC.
  final void Function(BuildContext context, A action) listener;

  /// Builds the widget tree from the current state.
  final BlocWidgetBuilder<S> builder;

  /// Optional filter for actions. When null, all actions are forwarded.
  final bool Function(A action)? listenWhen;

  /// Optional rebuild filter. When null, rebuilds on every state change.
  final BlocBuilderCondition<S>? buildWhen;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<B?>('bloc', bloc))
      ..add(
        ObjectFlagProperty<void Function(BuildContext, A)>.has(
          'listener',
          listener,
        ),
      )
      ..add(ObjectFlagProperty<BlocWidgetBuilder<S>>.has('builder', builder));
  }

  @override
  Widget build(BuildContext context) => ActionBlocListener<B, S, A>(
    bloc: bloc,
    listener: listener,
    listenWhen: listenWhen,
    child: BlocBuilder<B, S>(
      bloc: bloc,
      buildWhen: buildWhen,
      builder: builder,
    ),
  );
}
