import 'package:keys/keys.dart';
import 'package:transaction/transaction.dart';

sealed class SigningAction {}

/// No native SegWit addresses exist for the wallet — generate some first.
final class SigningNoAddressesFound extends SigningAction {}

/// No UTXOs found during scan — nothing to spend.
final class SigningNoUtxosFound extends SigningAction {}

/// Key derivation or signing failed.
final class SigningKeysFailed extends SigningAction {
  final KeysException exception;

  SigningKeysFailed({required this.exception});
}

/// UTXO scan or broadcast failed.
final class SigningTransactionFailed extends SigningAction {
  final TransactionException exception;

  SigningTransactionFailed({required this.exception});
}
