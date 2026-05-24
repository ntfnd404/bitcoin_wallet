import 'package:action_bloc/action_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Spy [BlocObserver] that records every [onAction] call for later assertion.
final class SpyActionBlocObserver extends BlocObserver with ActionBlocObserver {
  final List<({BlocBase<Object?> bloc, ActionChange<Object?> change})> records = [];

  @override
  void onAction(BlocBase<Object?> bloc, ActionChange<Object?> change) {
    records.add((bloc: bloc, change: change));
  }
}
