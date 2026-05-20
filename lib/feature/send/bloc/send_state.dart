import 'package:bitcoin_wallet/feature/send/bloc/coin_selection_mode.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_status.dart';
import 'package:transaction/transaction.dart';

final class SendState {
  final SendStatus status;
  final SendPreparation? preparation;
  final List<CoinSelectionStrategyResult>? strategies;
  final String? selectedStrategy;
  final CoinSelectionMode selectionMode;
  final String? changeAddress;
  final String? recipientAddress;
  final int? amountSat;
  final int? feeRateSatPerVbyte;
  final String? txid;

  const SendState({
    this.status = SendStatus.idle,
    this.preparation,
    this.strategies,
    this.selectedStrategy,
    this.selectionMode = CoinSelectionMode.auto,
    this.changeAddress,
    this.recipientAddress,
    this.amountSat,
    this.feeRateSatPerVbyte,
    this.txid,
  });

  SendState copyWith({
    SendStatus? status,
    SendPreparation? preparation,
    List<CoinSelectionStrategyResult>? strategies,
    String? selectedStrategy,
    CoinSelectionMode? selectionMode,
    String? changeAddress,
    String? recipientAddress,
    int? amountSat,
    int? feeRateSatPerVbyte,
    String? txid,
  }) => SendState(
    status: status ?? this.status,
    preparation: preparation ?? this.preparation,
    strategies: strategies ?? this.strategies,
    selectedStrategy: selectedStrategy ?? this.selectedStrategy,
    selectionMode: selectionMode ?? this.selectionMode,
    changeAddress: changeAddress ?? this.changeAddress,
    recipientAddress: recipientAddress ?? this.recipientAddress,
    amountSat: amountSat ?? this.amountSat,
    feeRateSatPerVbyte: feeRateSatPerVbyte ?? this.feeRateSatPerVbyte,
    txid: txid ?? this.txid,
  );
}
