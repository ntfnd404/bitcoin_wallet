import 'package:transaction/src/domain/entity/transaction.dart';
import 'package:transaction/src/domain/entity/transaction_input.dart';
import 'package:transaction/src/domain/entity/transaction_output.dart';

/// Full transaction detail: base transaction data plus decoded structure.
///
/// Fetched on demand via `gettransaction` RPC — separate from the lightweight
/// [Transaction] that comes from `listtransactions`.
final class TransactionDetail {
  /// Base transaction (direction, amount, confirmations, timestamp, etc.).
  final Transaction transaction;

  /// Decoded transaction inputs in order.
  final List<TransactionInput> inputs;

  /// Decoded transaction outputs in order.
  final List<TransactionOutput> outputs;

  /// Transaction size in bytes (non-witness serialisation).
  final int size;

  /// Transaction weight units (witness-aware metric).
  final int weight;

  /// Raw transaction hex.
  final String hex;

  const TransactionDetail({
    required this.transaction,
    required this.inputs,
    required this.outputs,
    required this.size,
    required this.weight,
    required this.hex,
  });
}
