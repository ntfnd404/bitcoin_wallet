import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_filter.dart';
import 'package:wallet/wallet.dart';

sealed class TransactionEvent {
  const TransactionEvent();
}

final class TransactionListRequested extends TransactionEvent {
  final Wallet wallet;

  const TransactionListRequested({required this.wallet});
}

final class TransactionRefreshRequested extends TransactionEvent {
  final Wallet wallet;

  const TransactionRefreshRequested({required this.wallet});
}

final class TransactionFilterChanged extends TransactionEvent {
  final TransactionFilter filter;

  const TransactionFilterChanged({required this.filter});
}
