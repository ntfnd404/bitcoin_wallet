import 'package:action_bloc/action_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class StubActionBloc extends Bloc<Object, int> with ActionBlocMixin<int, String> {
  StubActionBloc() : super(0) {
    on<Object>((_, emit) => emit(state + 1));
  }
}
