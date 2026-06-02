import 'package:transaction/transaction.dart';

final class FakeUtxoSource implements UtxoSource {
  UtxoSourceResult result = const UtxoSourceResult(
    candidates: [],
    changeAddress: 'bcrt1qchange',
    signingContext: NodeSignerPayload(),
  );

  Object? throwOnResolve;

  @override
  Future<UtxoSourceResult> resolve() async {
    final t = throwOnResolve;
    if (t != null) throw t;

    return result;
  }
}
