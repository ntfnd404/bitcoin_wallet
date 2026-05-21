import 'package:flutter_bloc/flutter_bloc.dart';

/// Records every error forwarded via [BlocBase.addError] for test assertions.
class ErrorCapturingObserver extends BlocObserver {
  final List<Object> errors = [];

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(bloc, error, stackTrace);
  }
}
