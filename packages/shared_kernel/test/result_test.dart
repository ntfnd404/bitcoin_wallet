import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';

import 'stub_failure.dart';

void main() {
  group('Success', () {
    test('carries value and is accessible via .value', () {
      const result = Success<int, StubFailure>(42);

      expect(result.value, equals(42));
    });

    test('const Success compiles as a constant expression', () {
      const result = Success<String, StubFailure>('ok');

      expect(result.value, equals('ok'));
    });

    test('pattern matching with destructuring works', () {
      const Result<int, StubFailure> result = Success(7);

      final extracted = switch (result) {
        Success(:final value) => value,
        Failure(:final failure) => throw StateError('unexpected: $failure'),
      };

      expect(extracted, equals(7));
    });
  });

  group('Failure', () {
    test('carries failure and is accessible via .failure', () {
      const result = Failure<int, StubFailure>(StubFailure('error'));

      expect(result.failure.message, equals('error'));
    });

    test('const Failure compiles as a constant expression', () {
      const result = Failure<String, StubFailure>(StubFailure('bad'));

      expect(result.failure.message, equals('bad'));
    });

    test('pattern matching with destructuring works', () {
      const Result<int, StubFailure> result = Failure(StubFailure('destructured'));

      final extracted = switch (result) {
        Success(:final value) => throw StateError('unexpected: $value'),
        Failure(:final failure) => failure.message,
      };

      expect(extracted, equals('destructured'));
    });
  });

  group('Result switch exhaustiveness', () {
    test('switch on Result covers both Success and Failure branches', () {
      const Result<String, StubFailure> success = Success('hello');
      const Result<String, StubFailure> failure = Failure(StubFailure('oops'));

      String resolve(Result<String, StubFailure> r) => switch (r) {
        Success(:final value) => 'success:$value',
        Failure(:final failure) => 'failure:${failure.message}',
      };

      expect(resolve(success), equals('success:hello'));
      expect(resolve(failure), equals('failure:oops'));
    });
  });

  group('Result<void, AppFailure>', () {
    test('void-typed result works with Success(null)', () {
      // ignore: void_checks
      const Result<void, StubFailure> result = Success(null);

      final label = switch (result) {
        Success() => 'ok',
        Failure() => 'fail',
      };

      expect(label, equals('ok'));
    });
  });
}
