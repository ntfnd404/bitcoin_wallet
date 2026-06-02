import 'package:transaction/transaction.dart';

/// Test fake for the [UtxoSource] interface.
///
/// Configurable `result` returned by [resolve]; setting [throwOnResolve] makes
/// the next call throw that object (any [Object]).
final class FakeUtxoSource implements UtxoSource {
  UtxoSourceResult result = const UtxoSourceResult(
    candidates: [],
    changeAddress: '',
    signingContext: NodeSignerPayload(),
  );

  Object? throwOnResolve;

  int resolveCallCount = 0;

  @override
  Future<UtxoSourceResult> resolve() async {
    resolveCallCount += 1;
    final t = throwOnResolve;
    if (t != null) throw t;

    return result;
  }
}
