import 'package:transaction/src/application/hd/hd_send_preparation.dart';
import 'package:transaction/src/application/node/node_send_preparation.dart';
import 'package:transaction/src/domain/value_object/coin_selection_strategy_result.dart';

/// Opaque result of [SendWorkflow.prepare].
///
/// Exposes only the fields needed for UI rendering. Subtypes must not be
/// downcast or inspected outside the workflow implementation.
sealed class SendPreparation {
  /// All coin-selection results computed during preparation, ordered by strategy.
  final List<CoinSelectionStrategyResult> strategies;

  /// Change address allocated for this preparation.
  final String changeAddress;

  const SendPreparation({
    required this.strategies,
    required this.changeAddress,
  });

  /// Creates a [SendPreparation] for use in tests.
  ///
  /// Provides a concrete instance without requiring access to the internal
  /// [NodeSendResult]/[HdSendResult] subtypes.
  static SendPreparation forTest({
    required List<CoinSelectionStrategyResult> strategies,
    required String changeAddress,
  }) =>
      _TestSendPreparation(strategies: strategies, changeAddress: changeAddress);
}

final class _TestSendPreparation extends SendPreparation {
  const _TestSendPreparation({
    required super.strategies,
    required super.changeAddress,
  });
}

/// Node-wallet variant. Internal — not exported from transaction barrel separately.
final class NodeSendResult extends SendPreparation {
  /// Not accessible from outside the transaction package application layer.
  final NodeSendPreparation inner;

  const NodeSendResult({
    required super.strategies,
    required super.changeAddress,
    required this.inner,
  });
}

/// HD-wallet variant. Internal — not exported from transaction barrel separately.
final class HdSendResult extends SendPreparation {
  /// Not accessible from outside the transaction package application layer.
  final HdSendPreparation inner;

  const HdSendResult({
    required super.strategies,
    required super.changeAddress,
    required this.inner,
  });
}
