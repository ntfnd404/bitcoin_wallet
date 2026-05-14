import 'package:transaction/src/domain/entity/transaction_detail.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/repository/transaction_repository.dart';

/// Fetches full detail for a single transaction from Bitcoin Core.
///
/// Calls `gettransaction <txid> true` via the repository to get decoded
/// inputs, outputs, size, weight, and raw hex.
final class GetTransactionDetailUseCase {
  final TransactionRepository _repository;

  const GetTransactionDetailUseCase({required TransactionRepository repository}) : _repository = repository;

  Future<TransactionDetail> call(String txid, String walletName) async {
    try {
      return await _repository.getTransactionDetail(txid, walletName);
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
