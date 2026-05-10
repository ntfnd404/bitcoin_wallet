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
    } catch (e, stack) {
      Error.throwWithStackTrace(const TransactionFetchException(), stack);
    }
  }
}
