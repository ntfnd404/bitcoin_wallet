import 'package:wallet/wallet.dart';

/// Base class for UTXO-related events.
sealed class UtxoEvent {
  const UtxoEvent();
}

/// Request to fetch UTXO list for a wallet.
final class UtxoListRequested extends UtxoEvent {
  final Wallet wallet;

  const UtxoListRequested({required this.wallet});
}

/// Request to refresh the UTXO list (keeps current state during load).
final class UtxoRefreshRequested extends UtxoEvent {
  final Wallet wallet;

  const UtxoRefreshRequested({required this.wallet});
}
