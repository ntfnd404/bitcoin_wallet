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
