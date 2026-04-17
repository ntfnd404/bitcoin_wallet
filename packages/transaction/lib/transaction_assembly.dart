import 'package:transaction/src/application/get_transactions_use_case.dart';
import 'package:transaction/src/application/get_utxos_use_case.dart';
import 'package:transaction/src/data/transaction_repository_impl.dart';
import 'package:transaction/src/data/utxo_repository_impl.dart';
import 'package:transaction/src/domain/data_sources/transaction_remote_data_source.dart';
import 'package:transaction/src/domain/repository/transaction_repository.dart';
import 'package:transaction/src/domain/repository/utxo_repository.dart';

final class TransactionAssembly {
  final TransactionRepository transactionRepository;
  final UtxoRepository utxoRepository;
  final GetTransactionsUseCase getTransactions;
  final GetUtxosUseCase getUtxos;

  factory TransactionAssembly({
    required TransactionRemoteDataSource remoteDataSource,
  }) {
    final txRepo = TransactionRepositoryImpl(remoteDataSource: remoteDataSource);
    final utxoRepo = UtxoRepositoryImpl(remoteDataSource: remoteDataSource);

    return TransactionAssembly._(
      transactionRepository: txRepo,
      utxoRepository: utxoRepo,
      getTransactions: GetTransactionsUseCase(repository: txRepo),
      getUtxos: GetUtxosUseCase(repository: utxoRepo),
    );
  }

  const TransactionAssembly._({
    required this.transactionRepository,
    required this.utxoRepository,
    required this.getTransactions,
    required this.getUtxos,
  });
}
