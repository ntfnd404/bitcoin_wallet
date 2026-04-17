import 'package:transaction/src/domain/data_sources/transaction_remote_data_source.dart';
import 'package:transaction/src/domain/entity/transaction.dart';
import 'package:transaction/src/domain/repository/transaction_repository.dart';

/// [TransactionRepository] backed by [TransactionRemoteDataSource].
///
/// Transactions are never cached locally — always fresh from the node.
final class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource _remoteDataSource;

  const TransactionRepositoryImpl({
    required TransactionRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Transaction>> getTransactions(String walletName) =>
      _remoteDataSource.getTransactions(walletName);
}
