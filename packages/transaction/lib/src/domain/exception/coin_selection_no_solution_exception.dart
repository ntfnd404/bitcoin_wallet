/// Thrown by [BranchAndBoundCoinSelector] when no exact-match subset exists.
///
/// This is distinct from [InsufficientFundsException]: funds are sufficient
/// to cover the target, but no subset sums to exactly target + fee (zero change).
///
/// Public within the package so Prepare*UseCases can catch it; intentionally
/// NOT exported from `transaction.dart` barrel.
final class CoinSelectionNoSolutionException implements Exception {
  const CoinSelectionNoSolutionException();

  @override
  String toString() => 'CoinSelectionNoSolutionException: no exact-match subset found';
}
