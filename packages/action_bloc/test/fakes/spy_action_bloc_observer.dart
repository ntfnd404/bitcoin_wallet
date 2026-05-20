import 'package:action_bloc/action_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Spy [BlocObserver] that records every [onAction] call for later assertion.
final class SpyActionBlocObserver extends BlocObserver implements ActionBlocObserver {
  final List<({BlocBase<dynamic> bloc, Object? action})> records = [];

  @override
  void onAction(BlocBase<dynamic> bloc, Object? action) {
    records.add((bloc: bloc, action: action));
  }
}
