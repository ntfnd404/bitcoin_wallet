import 'package:shared_kernel/src/failure/app_failure.dart';

/// Discriminated union representing the outcome of an operation.
///
/// Use [switch] for exhaustive handling — no [default] branch needed:
/// ```dart
/// switch (result) {
///   case Success(:final value) => ...,
///   case Failure(:final failure) => ...,
/// }
/// ```
sealed class Result<T, F extends AppFailure> {
  const Result();
}

/// The success variant of [Result]. Carries the operation output.
final class Success<T, F extends AppFailure> extends Result<T, F> {
  const Success(this.value);

  final T value;
}

/// The failure variant of [Result]. Carries the typed domain failure.
final class Failure<T, F extends AppFailure> extends Result<T, F> {
  const Failure(this.failure);

  final F failure;
}
