import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_status.dart';
import 'package:transaction/transaction.dart';

export 'signing_status.dart';

final class SigningState {
  final SigningStatus status;
  final List<ScannedUtxo> utxos;
  final String? txid;
  final BroadcastedTx? broadcastedTx;
  final Exception? exception;

  const SigningState({
    this.status = SigningStatus.initial,
    this.utxos = const [],
    this.txid,
    this.broadcastedTx,
    this.exception,
  });

  SigningState copyWith({
    SigningStatus? status,
    List<ScannedUtxo>? utxos,
    String? txid,
    BroadcastedTx? broadcastedTx,
    Exception? exception,
  }) => SigningState(
    status: status ?? this.status,
    utxos: utxos ?? this.utxos,
    txid: txid ?? this.txid,
    broadcastedTx: broadcastedTx ?? this.broadcastedTx,
    exception: exception ?? this.exception,
  );
}
