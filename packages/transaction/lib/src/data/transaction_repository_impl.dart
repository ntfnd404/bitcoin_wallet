import 'package:transaction/src/domain/entity/transaction.dart';
import 'package:transaction/src/domain/entity/transaction_detail.dart';
import 'package:transaction/src/domain/gateway/transaction_history_gateway.dart';
import 'package:transaction/src/domain/repository/transaction_repository.dart';

/// [TransactionRepository] backed by [TransactionHistoryGateway].
///
/// Transactions are never cached locally — always fresh from the node.
final class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionHistoryGateway _remoteDataSource;

  const TransactionRepositoryImpl({
    required TransactionHistoryGateway remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Transaction>> getTransactions(String walletName) => _remoteDataSource.getTransactions(walletName);

  @override
  Future<TransactionDetail> getTransactionDetail(String txid, String walletName) =>
      _remoteDataSource.getTransactionDetail(txid, walletName);
}
