import 'dart:async';

import 'package:bitcoin_wallet/core/bloc/bloc_action_mixin.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';

/// Listens to one-shot actions emitted by a BLoC that uses [BlocActionMixin].
///
/// Compatible with [MultiBlocListener] via [SingleChildStatefulWidget].
///
/// Usage:
/// ```dart
/// BlocActionListener<MyBloc, MyState, MyAction>(
///   listener: (context, action) => switch (action) {
///     MyActionA() => ...,
///     MyActionB(:final data) => ...,
///   },
///   child: ...,
/// )
/// ```
class BlocActionListener<B extends BlocBase<S>, S, A>
    extends SingleChildStatefulWidget {
  const BlocActionListener({
    super.key,
    required this.listener,
    this.listenWhen,
    super.child,
  });

  /// Called on the main isolate for each emitted action.
  final void Function(BuildContext context, A action) listener;

  /// Optional filter. When null, all actions are forwarded.
  ///
  /// Unlike [BlocListener.listenWhen], there is no previous action —
  /// actions are one-shot and not stored.
  final bool Function(A action)? listenWhen;

  @override
  SingleChildState<BlocActionListener<B, S, A>> createState() =>
      _BlocActionListenerState<B, S, A>();
}

class _BlocActionListenerState<B extends BlocBase<S>, S, A>
    extends SingleChildState<BlocActionListener<B, S, A>> {
  StreamSubscription<A>? _subscription;
  late B _bloc;

  void _subscribe() {
    final mixin = _bloc as BlocActionMixin<S, A>;
    _subscription = mixin.actionStream.listen((action) {
      if (!mounted) return;
      if (widget.listenWhen?.call(action) ?? true) {
        widget.listener(context, action);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = context.read<B>();
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
  Widget buildWithChild(BuildContext context, Widget? child) =>
      child ?? const SizedBox.shrink();
}
