import 'package:bitcoin_wallet/feature/send/bloc/coin_selection_mode.dart';

sealed class SendEvent {
  const SendEvent();
}

/// User submitted the send form — triggers coin selection for all strategies.
///
/// Wallet identity is captured in [SendWorkflow] at construction time.
/// This event carries only user-entered scalars.
final class SendFormSubmitted extends SendEvent {
  final String recipientAddress;
  final int amountSat;
  final int feeRateSatPerVbyte;

  const SendFormSubmitted({
    required this.recipientAddress,
    required this.amountSat,
    required this.feeRateSatPerVbyte,
  });
}

/// User selected a specific strategy from the comparison table.
/// Implicitly switches selection mode to [CoinSelectionMode.manual].
final class SendStrategySelected extends SendEvent {
  final String strategyName;

  const SendStrategySelected({required this.strategyName});
}

/// User toggled the Auto/Manual selection mode.
///
/// [CoinSelectionMode.auto]: re-runs `recommendStrategy()` to pick the best.
/// [CoinSelectionMode.manual]: preserves current selection; user chooses explicitly.
final class SendSelectionModeChanged extends SendEvent {
  final CoinSelectionMode mode;

  const SendSelectionModeChanged({required this.mode});
}

/// User confirmed the selected strategy — triggers sign + broadcast.
final class SendConfirmed extends SendEvent {
  const SendConfirmed();
}
