import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:transaction/transaction.dart';

/// State container for UTXO list and fetch status.
final class UtxoState {
  final List<Utxo> utxos;
  final FetchStatus status;
  final Exception? exception;

  const UtxoState({
    this.utxos = const [],
    this.status = FetchStatus.initial,
    this.exception,
  });

  /// Creates a copy with optional field overrides.
  UtxoState copyWith({
    List<Utxo>? utxos,
    FetchStatus? status,
    Exception? exception,
    bool clearException = false,
  }) => UtxoState(
    utxos: utxos ?? this.utxos,
    status: status ?? this.status,
    exception: clearException ? null : (exception ?? this.exception),
  );
}
