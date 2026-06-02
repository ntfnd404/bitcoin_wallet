import 'package:transaction/src/domain/value_object/coin_selection_strategy_result.dart';
import 'package:transaction/src/domain/value_object/signer_payload.dart';

/// Opaque result of [SendWorkflow.prepare].
///
/// Exposes only the fields needed for UI rendering. Subtypes must not be
/// downcast or inspected outside the workflow implementation.
sealed class SendPreparation {
  /// All coin-selection results computed during preparation, ordered by strategy.
  final List<CoinSelectionStrategyResult> strategies;

  /// Strategy names that were skipped because they found no viable solution
  /// (e.g. BnB requires an exact match; SmallestSingle needs a single coin ≥ target).
  final List<String> failedStrategies;

  /// Change address allocated for this preparation.
  final String changeAddress;

  /// Signing context produced during UTXO resolution — used by [SendWorkflow.confirm].
  SignerPayload get signingContext;

  const SendPreparation({
    required this.strategies,
    required this.changeAddress,
    this.failedStrategies = const [],
  });
}

/// Returned by [PrepareSendUseCase] — carries [signingContext] directly without a legacy inner wrapper.
final class SendPreparationResult extends SendPreparation {
  @override
  final SignerPayload signingContext;

  const SendPreparationResult({
    required super.strategies,
    required super.changeAddress,
    required this.signingContext,
    super.failedStrategies,
  });
}
