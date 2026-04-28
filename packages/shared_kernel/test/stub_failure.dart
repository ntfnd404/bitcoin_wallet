import 'package:shared_kernel/shared_kernel.dart';

/// Minimal [AppFailure] subtype for use in unit tests.
final class StubFailure extends AppFailure {
  final String message;

  const StubFailure(this.message);
}
