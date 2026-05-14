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
    } on TransactionException {
      rethrow;
    } on Exception catch (_, stack) {
      // 4-criteria (C1: translate to BC language, C2: n/a — no sensitive material, C3: preserve stack, C4: typed recovery for caller).
      // TODO(ntfnd404): narrow to on RpcException once rpc_client dep is wired in pubspec.
      Error.throwWithStackTrace(const TransactionFetchException(), stack);
    }
    // Programmer errors propagate.
  }
}
