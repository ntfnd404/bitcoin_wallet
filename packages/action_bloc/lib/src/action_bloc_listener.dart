import 'dart:async';

import 'package:action_bloc/src/action_bloc_mixin.dart';
import 'package:action_bloc/src/action_bloc_streamable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';

/// Listens to one-shot actions emitted by a BLoC that uses [ActionBlocMixin].
///
/// Compatible with [MultiBlocListener] via [SingleChildStatefulWidget].
///
/// If [bloc] is omitted the nearest [BlocProvider] ancestor is used.
///
/// Usage:
/// ```dart
/// ActionBlocListener<MyBloc, MyState, MyAction>(
///   listener: (context, action) => switch (action) {
///     MyActionA() => ...,
///     MyActionB(:final data) => ...,
///   },
///   child: ...,
/// )
/// ```
class ActionBlocListener<B extends BlocBase<S>, S, A> extends SingleChildStatefulWidget {
  const ActionBlocListener({
    super.key,
    required this.listener,
    this.bloc,
    this.listenWhen,
    super.child,
  });

  /// The BLoC to subscribe to. When null, resolved via [context.read].
  final B? bloc;

  /// Called on the main isolate for each emitted action.
  final void Function(BuildContext context, A action) listener;

  /// Optional filter. When null, all actions are forwarded.
  ///
  /// Unlike [BlocListener.listenWhen], there is no previous action —
  /// actions are one-shot and not stored.
  final bool Function(A action)? listenWhen;

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
      );
  }

  @override
  SingleChildState<ActionBlocListener<B, S, A>> createState() => _ActionBlocListenerState<B, S, A>();
}

class _ActionBlocListenerState<B extends BlocBase<S>, S, A> extends SingleChildState<ActionBlocListener<B, S, A>> {
  StreamSubscription<A>? _subscription;
  late B _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<B>();
    _subscribe();
  }

  void _subscribe() {
    if (_bloc is! ActionBlocStreamable<A>) {
      throw StateError(
        '$B does not implement ActionBlocStreamable<$A>. '
        'Mix ActionBlocMixin into $B or implement the streamable contract '
        'to use ActionBlocListener.',
      );
    }
    final actionBloc = _bloc as ActionBlocStreamable<A>;
    _subscription = actionBloc.actionStream.listen((action) {
      if (!mounted) return;
      if (widget.listenWhen?.call(action) ?? true) {
        widget.listener(context, action);
      }
    });
  }

  @override
  void didUpdateWidget(ActionBlocListener<B, S, A> old) {
    super.didUpdateWidget(old);
    // When both [old.bloc] and [widget.bloc] are null the BLoC is resolved from
    // the nearest provider — [context.read<B>()] returns the same instance, so
    // [oldBloc == current] and no resubscription occurs. This is intentional.
    final oldBloc = old.bloc ?? context.read<B>();
    final current = widget.bloc ?? oldBloc;
    if (oldBloc != current) {
      _subscription?.cancel();
      _bloc = current;
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.bloc ?? context.read<B>();
    if (_bloc != bloc) {
      _subscription?.cancel();
      _bloc = bloc;
      _subscribe();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) => child ?? const SizedBox.shrink();
}
