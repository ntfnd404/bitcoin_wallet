import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Observes all BLoC instances in the app.
///
/// [onError] is the single integration point for error reporting:
/// errors reported via `addError(e, stack)` inside any BLoC flow through
/// here before reaching crash reporters (Sentry, Firebase Crashlytics).
///
/// Registered in [AppBootstrap.initialize].
final class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log(
      '${bloc.runtimeType}: $error\n$stackTrace',
      name: 'BlocObserver',
      level: 1000,
    );

    // TODO(ntfnd404): forward to Sentry here, e.g.:
    // Sentry.captureException(error, stackTrace: stackTrace);

    super.onError(bloc, error, stackTrace);
  }
}
