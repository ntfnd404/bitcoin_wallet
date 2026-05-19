/// Thrown by [BranchAndBoundCoinSelector] when no changeless economic match exists.
///
/// This is distinct from [InsufficientFundsException]: funds are sufficient
/// to cover the target, but no subset of candidates has an effective value in
/// the range `[targetEffective, targetEffective + costOfChange]`.
/// In other words: the selector cannot find a combination where omitting the
/// change output is economically rational.
///
/// Public within the package so Prepare*UseCases can catch it; intentionally
/// NOT exported from `transaction.dart` barrel.
final class CoinSelectionNoSolutionException implements Exception {
  const CoinSelectionNoSolutionException();

  @override
  String toString() =>
      'CoinSelectionNoSolutionException: no changeless economic match found';
}
