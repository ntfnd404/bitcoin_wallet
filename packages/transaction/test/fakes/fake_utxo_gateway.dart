import 'package:transaction/transaction.dart';

final class FakeUtxoGateway implements UtxoGateway {
  @override
  Future<List<Utxo>> getUtxos(String walletName) async => const [];
}
