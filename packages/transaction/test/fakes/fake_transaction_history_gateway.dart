import 'package:transaction/transaction.dart';

final class FakeTransactionHistoryGateway implements TransactionHistoryGateway {
  @override
  Future<List<Transaction>> getTransactions(String walletName) async => const [];

  @override
  Future<TransactionDetail> getTransactionDetail(String txid, String walletName) => throw UnimplementedError();
}
