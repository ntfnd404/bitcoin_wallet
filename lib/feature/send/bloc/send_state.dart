import 'package:bitcoin_wallet/feature/send/bloc/send_status.dart';
import 'package:transaction/transaction.dart';

final class SendState {
  final SendStatus status;
  final SendPreparation? preparation;
  final Map<String, CoinSelectionResult>? strategies;
  final String? selectedStrategy;
  final String? changeAddress;
  final String? recipientAddress;
  final int? amountSat;
  final String? txid;

  const SendState({
    this.status = SendStatus.idle,
    this.preparation,
    this.strategies,
    this.selectedStrategy,
    this.changeAddress,
    this.recipientAddress,
    this.amountSat,
    this.txid,
  });

  SendState copyWith({
    SendStatus? status,
    SendPreparation? preparation,
    Map<String, CoinSelectionResult>? strategies,
    String? selectedStrategy,
    String? changeAddress,
    String? recipientAddress,
    int? amountSat,
    String? txid,
  }) => SendState(
    status: status ?? this.status,
    preparation: preparation ?? this.preparation,
    strategies: strategies ?? this.strategies,
    selectedStrategy: selectedStrategy ?? this.selectedStrategy,
    changeAddress: changeAddress ?? this.changeAddress,
    recipientAddress: recipientAddress ?? this.recipientAddress,
    amountSat: amountSat ?? this.amountSat,
    txid: txid ?? this.txid,
  );
}
