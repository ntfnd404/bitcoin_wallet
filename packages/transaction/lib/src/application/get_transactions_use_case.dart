import 'package:transaction/src/domain/entity/transaction.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/repository/transaction_repository.dart';

/// Returns all wallet transactions ordered by most recent first.
final class GetTransactionsUseCase {
  final TransactionRepository _repository;

  const GetTransactionsUseCase({required TransactionRepository repository}) : _repository = repository;

  Future<List<Transaction>> call(String walletName) async {
    try {
      return await _repository.getTransactions(walletName);
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
