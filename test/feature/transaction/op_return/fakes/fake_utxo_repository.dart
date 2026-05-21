import 'package:transaction/transaction.dart';

final class FakeUtxoRepository implements UtxoRepository {
  final List<Utxo> utxos;

  FakeUtxoRepository(this.utxos);

  @override
  Future<List<Utxo>> getUtxos(String walletName) async => utxos;
}
