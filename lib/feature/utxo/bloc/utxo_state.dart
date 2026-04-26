import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:transaction/transaction.dart';

/// State container for UTXO list and fetch status.
final class UtxoState {
  final List<Utxo> utxos;
  final FetchStatus status;
  final String? errorMessage;

  const UtxoState({
    this.utxos = const [],
    this.status = FetchStatus.initial,
    this.errorMessage,
  });

  /// Creates a copy with optional field overrides.
  UtxoState copyWith({
    List<Utxo>? utxos,
    FetchStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) => UtxoState(
    utxos: utxos ?? this.utxos,
    status: status ?? this.status,
    errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
  );
}
