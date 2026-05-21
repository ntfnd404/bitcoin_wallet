import 'package:keys/keys.dart';
import 'package:transaction/transaction.dart';

sealed class SigningAction {}

/// No native SegWit addresses exist for the wallet — generate some first.
final class SigningNoAddressesFoundAction extends SigningAction {}

/// No UTXOs found during scan — nothing to spend.
final class SigningNoUtxosFoundAction extends SigningAction {}

/// Key derivation or signing failed.
final class SigningKeysFailedAction extends SigningAction {
  final KeysException exception;

  SigningKeysFailedAction({required this.exception});
}

/// UTXO scan or broadcast failed.
final class SigningTransactionFailedAction extends SigningAction {
  final TransactionException exception;

  SigningTransactionFailedAction({required this.exception});
}

/// Transaction was broadcast successfully but getrawtransaction verification failed.
///
/// The txid is still visible in state; hex and confirmations are absent.
final class SigningVerificationFailedAction extends SigningAction {}
