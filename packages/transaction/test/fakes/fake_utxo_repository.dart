import 'package:transaction/transaction.dart';

final class FakeUtxoRepository implements UtxoRepository {
  List<Utxo> utxos = const [];
  Object? throwOnGet;

  @override
  Future<List<Utxo>> getUtxos(String walletName) async {
    final t = throwOnGet;
    if (t != null) throw t;

    return utxos;
  }
}
