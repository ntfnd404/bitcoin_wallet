import 'package:transaction/transaction.dart';

enum TransactionFilter {
  all,
  incoming,
  outgoing;

  bool matches(Transaction tx) => switch (this) {
    TransactionFilter.all => true,
    TransactionFilter.incoming => tx.direction == TransactionDirection.incoming,
    TransactionFilter.outgoing => tx.direction == TransactionDirection.outgoing,
  };

  String get label => switch (this) {
    TransactionFilter.all => 'All',
    TransactionFilter.incoming => 'Incoming',
    TransactionFilter.outgoing => 'Outgoing',
  };
}
