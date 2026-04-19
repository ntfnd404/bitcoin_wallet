import 'package:bitcoin_wallet/feature/signing/send/bloc/signing_status.dart';
import 'package:transaction/transaction.dart';

export 'signing_status.dart';

final class SigningState {
  final SigningStatus status;
  final List<ScannedUtxo> utxos;
  final String? txid;
  final BroadcastedTx? broadcastedTx;
  final String? errorMessage;

  const SigningState({
    this.status = SigningStatus.initial,
    this.utxos = const [],
    this.txid,
    this.broadcastedTx,
    this.errorMessage,
  });

  SigningState copyWith({
    SigningStatus? status,
    List<ScannedUtxo>? utxos,
    String? txid,
    BroadcastedTx? broadcastedTx,
    String? errorMessage,
  }) =>
      SigningState(
        status: status ?? this.status,
        utxos: utxos ?? this.utxos,
        txid: txid ?? this.txid,
        broadcastedTx: broadcastedTx ?? this.broadcastedTx,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
