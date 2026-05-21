import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:transaction/transaction.dart';

final class UtxoState {
  final List<Utxo> utxos;
  final FetchStatus status;

  const UtxoState({
    this.utxos = const [],
    this.status = FetchStatus.idle,
  });

  UtxoState copyWith({
    List<Utxo>? utxos,
    FetchStatus? status,
  }) => UtxoState(
    utxos: utxos ?? this.utxos,
    status: status ?? this.status,
  );
}
