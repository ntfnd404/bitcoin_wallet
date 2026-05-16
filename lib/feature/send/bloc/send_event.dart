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

/// User selected a strategy from the comparison table.
final class SendStrategySelected extends SendEvent {
  final String strategyName;

  const SendStrategySelected({required this.strategyName});
}

/// User confirmed the selected strategy — triggers sign + broadcast.
final class SendConfirmed extends SendEvent {
  const SendConfirmed();
}
