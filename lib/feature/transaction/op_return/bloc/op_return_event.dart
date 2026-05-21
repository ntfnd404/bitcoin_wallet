sealed class OpReturnEvent {
  const OpReturnEvent();
}

/// User changed the OP_RETURN text input.
final class OpReturnDataChanged extends OpReturnEvent {
  final String text;

  const OpReturnDataChanged(this.text);
}

/// User changed the fee rate.
final class OpReturnFeeRateChanged extends OpReturnEvent {
  final int feeRateSatPerVbyte;

  const OpReturnFeeRateChanged(this.feeRateSatPerVbyte);
}

/// User tapped the Broadcast button.
final class OpReturnBroadcastRequested extends OpReturnEvent {
  const OpReturnBroadcastRequested();
}
