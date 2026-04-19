import 'package:shared_kernel/shared_kernel.dart';

/// Thrown by [CoinSelector] implementations when the total available balance
/// is insufficient to cover the target amount plus fees.
final class InsufficientFundsException implements Exception {
  final Satoshi available;
  final Satoshi required;

  const InsufficientFundsException({
    required this.available,
    required this.required,
  });

  @override
  String toString() =>
      'InsufficientFundsException: available ${available.value} sat, '
      'required ${required.value} sat';
}
