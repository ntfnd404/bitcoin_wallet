import 'package:transaction/src/domain/entity/transaction_detail.dart';
import 'package:transaction/src/domain/repository/transaction_repository.dart';

/// Fetches full detail for a single transaction from Bitcoin Core.
///
/// Calls `gettransaction <txid> true` via the repository to get decoded
/// inputs, outputs, size, weight, and raw hex.
final class GetTransactionDetailUseCase {
  final TransactionRepository _repository;

  const GetTransactionDetailUseCase({required TransactionRepository repository})
      : _repository = repository;

  Future<TransactionDetail> call(String txid, String walletName) =>
      _repository.getTransactionDetail(txid, walletName);
}
