import 'package:bitcoin_wallet/feature/send/bloc/send_status.dart';
import 'package:transaction/transaction.dart';

final class SendState {
  final SendStatus status;

  /// All strategy results for the comparison table.
  /// Available after [SendStatus.awaitingConfirmation].
  final Map<String, CoinSelectionResult>? strategies;

  /// Currently selected strategy name.
  final String? selectedStrategy;

  /// Change address used in the prepared transaction.
  final String? changeAddress;

  /// Cached form values — needed when [SendConfirmed] fires.
  final String? recipientAddress;
  final int? amountSat;

  /// Txid of the broadcast transaction.
  final String? txid;

  final String? errorMessage;

  const SendState({
    this.status = SendStatus.initial,
    this.strategies,
    this.selectedStrategy,
    this.changeAddress,
    this.recipientAddress,
    this.amountSat,
    this.txid,
    this.errorMessage,
  });

  SendState copyWith({
    SendStatus? status,
    Map<String, CoinSelectionResult>? strategies,
    String? selectedStrategy,
    String? changeAddress,
    String? recipientAddress,
    int? amountSat,
    String? txid,
    String? errorMessage,
  }) =>
      SendState(
        status: status ?? this.status,
        strategies: strategies ?? this.strategies,
        selectedStrategy: selectedStrategy ?? this.selectedStrategy,
        changeAddress: changeAddress ?? this.changeAddress,
        recipientAddress: recipientAddress ?? this.recipientAddress,
        amountSat: amountSat ?? this.amountSat,
        txid: txid ?? this.txid,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
