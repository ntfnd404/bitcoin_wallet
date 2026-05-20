import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/send_preparation.dart';

/// Contract for the two-step send flow.
///
/// Implementations capture wallet identity and all configuration at construction
/// time. The [confirm] method does NOT accept wallet identity parameters —
/// this is a correctness invariant preventing substitution of a different wallet
/// between [prepare] and [confirm].
abstract interface class SendWorkflow {
  /// Runs coin selection for all strategies.
  ///
  /// Returns a [SendPreparation] carrying [SendPreparation.strategies] and
  /// [SendPreparation.changeAddress] for UI rendering. The preparation is opaque
  /// to the caller — pass it back unchanged to [confirm].
  ///
  /// Throws [TransactionException] subtypes on domain failures.
  Future<SendPreparation> prepare({
    required Satoshi targetSat,
    required int feeRateSatPerVbyte,
  });

  /// Signs and broadcasts the transaction.
  ///
  /// [preparation] must be the value returned by the preceding [prepare] call
  /// on the same workflow instance.
  /// [strategyName] must be one of the keys from [SendPreparation.strategies].
  ///
  /// Returns the broadcast txid.
  /// Throws [TransactionException] subtypes on domain failures.
  Future<String> confirm({
    required SendPreparation preparation,
    required String strategyName,
    required String recipientAddress,
    required Satoshi amountSat,
  });
}
