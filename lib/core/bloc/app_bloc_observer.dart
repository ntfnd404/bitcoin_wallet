import 'dart:developer';

import 'package:action_bloc/action_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Observes all BLoC instances in the app.
///
/// [onError] is the single integration point for error reporting:
/// errors reported via `addError(e, stack)` inside any BLoC flow through
/// here before reaching crash reporters (Sentry, Firebase Crashlytics).
///
/// Registered in [AppBootstrap.initialize].
final class AppBlocObserver extends BlocObserver implements ActionBlocObserver {
  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    log(
      '${bloc.runtimeType}: $event',
      name: 'BlocObserver.event',
    );

    super.onEvent(bloc, event);
  }

  @override
  void onAction(BlocBase<dynamic> bloc, Object? action) {
    log(
      '${bloc.runtimeType}: $action',
      name: 'BlocObserver.action',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log(
      '${bloc.runtimeType}: $error\n$stackTrace',
      name: 'BlocObserver',
      level: 1000,
    );

    // TODO(ntfnd404): BW-XXXX — forward to crash reporter, e.g.:
    // Sentry.captureException(error, stackTrace: stackTrace);

    super.onError(bloc, error, stackTrace);
  }
}
