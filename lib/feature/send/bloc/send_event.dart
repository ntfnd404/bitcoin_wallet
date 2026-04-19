import 'package:wallet/wallet.dart';

sealed class SendEvent {
  const SendEvent();
}

/// User submitted the send form — triggers coin selection for all strategies.
final class SendFormSubmitted extends SendEvent {
  final Wallet wallet;
  final String recipientAddress;
  final int amountSat;
  final int feeRateSatPerVbyte;

  const SendFormSubmitted({
    required this.wallet,
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

/// User requested to mine one block (regtest dev helper).
final class MineBlockRequested extends SendEvent {
  final String toAddress;

  const MineBlockRequested({required this.toAddress});
}
