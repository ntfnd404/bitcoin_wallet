import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_status.dart';
import 'package:transaction/transaction.dart';

export 'signing_status.dart';

final class SigningState {
  final SigningStatus status;
  final List<ScannedUtxo> utxos;
  final Map<String, int> addressIndexMap;
  final String? txid;
  final BroadcastedTx? broadcastedTx;

  const SigningState({
    this.status = SigningStatus.idle,
    this.utxos = const [],
    this.addressIndexMap = const {},
    this.txid,
    this.broadcastedTx,
  });

  SigningState copyWith({
    SigningStatus? status,
    List<ScannedUtxo>? utxos,
    Map<String, int>? addressIndexMap,
    String? txid,
    BroadcastedTx? broadcastedTx,
  }) => SigningState(
    status: status ?? this.status,
    utxos: utxos ?? this.utxos,
    addressIndexMap: addressIndexMap ?? this.addressIndexMap,
    txid: txid ?? this.txid,
    broadcastedTx: broadcastedTx ?? this.broadcastedTx,
  );
}
