import 'package:transaction/src/domain/entity/utxo.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/repository/utxo_repository.dart';

/// Returns all unspent outputs for the wallet.
final class GetUtxosUseCase {
  final UtxoRepository _repository;

  const GetUtxosUseCase({required UtxoRepository repository}) : _repository = repository;

  Future<List<Utxo>> call(String walletName) async {
    try {
      return await _repository.getUtxos(walletName);
    } catch (e, stack) {
      Error.throwWithStackTrace(const TransactionFetchException(), stack);
    }
  }
}
