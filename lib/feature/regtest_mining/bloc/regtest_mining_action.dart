import 'package:transaction/transaction.dart';

sealed class RegtestMiningAction {}

/// Block mining failed with a known domain exception.
final class RegtestMiningFailedAction extends RegtestMiningAction {
  final TransactionException exception;

  RegtestMiningFailedAction({required this.exception});
}

/// Block mining failed with an unexpected programmer error.
///
/// Emitted alongside [Bloc.addError] so the zone handler gets the original
/// error while the UI still shows a generic failure message.
final class RegtestMiningUnexpectedFailedAction extends RegtestMiningAction {}
