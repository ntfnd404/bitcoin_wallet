import 'package:transaction/src/application/hd/hd_send_preparation.dart';
import 'package:transaction/src/application/node/node_send_preparation.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// Opaque result of [SendWorkflow.prepare].
///
/// Exposes only the fields needed for UI rendering. The inner preparation DTO
/// (HD or Node) is accessible only to the workflow implementation via internal
/// pattern matching. Feature-layer code (SendBloc, SendState) must never
/// downcast or inspect the subtype.
sealed class SendPreparation {
  final Map<String, CoinSelectionResult> strategies;
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
    required Map<String, CoinSelectionResult> strategies,
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
