import 'package:transaction/transaction.dart';

/// Maps Bitcoin Core RPC transaction categories to [TransactionDirection].
///
/// Single source of truth for category parsing.
/// Throws [ArgumentError] on unknown values to fail fast.
abstract final class TransactionDirectionRpcMapper {
  static TransactionDirection fromRpcCategory(String category) => switch (category) {
    'receive' || 'generate' || 'immature' => TransactionDirection.incoming,
    'send' => TransactionDirection.outgoing,
    _ => throw ArgumentError('Unknown RPC category: $category'),
  };
}
